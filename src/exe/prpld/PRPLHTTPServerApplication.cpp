#include "PRPLHTTPServerApplication.h"

#include "HandlerFactory.h"

#include "dataobject/Param.h"

#include "ResultsController.h"

#include <Poco/Net/ServerSocket.h>
#include <Poco/Net/HTTPServer.h>
#include <Poco/Util/HelpFormatter.h>

#include <Poco/SimpleFileChannel.h>
#include <Poco/SplitterChannel.h>
#include <Poco/ConsoleChannel.h>
#include <Poco/FormattingChannel.h>
#include <Poco/PatternFormatter.h>
#include <Poco/NumberParser.h>

#include <Poco/UTF8String.h>

#include <Poco/StringTokenizer.h>

#include <Poco/Data/Session.h>
#include <Poco/Data/SessionPool.h>
#include <Poco/Data/MySQL/Connector.h>

#include <Poco/Thread.h>

#include <vector>
#include <iostream>

// STATIC Poco::Data::SessionPool PRPLHTTPServerApplication::dbSessionPool;

PRPLHTTPServerApplication* PRPLHTTPServerApplication::_pInstance = NULL;



PRPLHTTPServerApplication::PRPLHTTPServerApplication() :
	_helpRequested(false),
	_appName("ParkRun Points League server"),
	_pDbSessionPool(NULL),
	_stopping(false),
	_pResultsHarvesterTimer(NULL)
{
	_schemaVersion.major = 0;
	_schemaVersion.minor = 1;
	_schemaVersion.release = 0;
	_schemaVersion.hotfix = 0;

	_pInstance = this;
}

VIRTUAL PRPLHTTPServerApplication::~PRPLHTTPServerApplication()
{
    _pInstance = NULL;

    if(_pDbSessionPool != NULL)
    {
        delete _pDbSessionPool;
    }
}

Poco::Data::SessionPool* PRPLHTTPServerApplication::getDbSessionPool()
{
	poco_check_ptr (_pDbSessionPool);

    return _pDbSessionPool;
}

bool PRPLHTTPServerApplication::isStopping() const
{
    return _stopping;
}

void PRPLHTTPServerApplication::initialize(Application& self)
{
	loadConfiguration();
	ServerApplication::initialize(self);
}

/*
void PRPLHTTPServerApplication::uninitialize()
{
}
*/

void PRPLHTTPServerApplication::defineOptions(Poco::Util::OptionSet& options)
{
	ServerApplication::defineOptions(options);

	Poco::Util::Option option("help", "h", "display argument help information");
	option.required(false);
	option.repeatable(false);
	option.callback(Poco::Util::OptionCallback<PRPLHTTPServerApplication>(this, &PRPLHTTPServerApplication::handleHelp));
	options.addOption(option);
}

void PRPLHTTPServerApplication::handleHelp(const std::string& name, const std::string& value)
{
	Poco::Util::HelpFormatter helpFormatter(options());

	helpFormatter.setCommand(commandName());
	helpFormatter.setUsage("OPTIONS");
	helpFormatter.setHeader(_appName);
	helpFormatter.format(std::cout);
	stopOptionsProcessing();
	_helpRequested = true;
}

int PRPLHTTPServerApplication::getLogLevel(const std::string& logLevelName)
{
	const std::string logLevelNameLower = Poco::UTF8::toLower(logLevelName);
	int logLevel = Poco::Message::PRIO_INFORMATION;

	if(logLevelNameLower == "fatal")
		logLevel = Poco::Message::PRIO_FATAL;
	else if(logLevelNameLower == "critical")
		logLevel = Poco::Message::PRIO_CRITICAL;
	else if(logLevelNameLower == "error")
		logLevel = Poco::Message::PRIO_ERROR;
	else if(logLevelNameLower == "warning")
		logLevel = Poco::Message::PRIO_WARNING;
	else if(logLevelNameLower == "notice")
		logLevel = Poco::Message::PRIO_NOTICE;
	else if(logLevelNameLower == "information")
		logLevel = Poco::Message::PRIO_INFORMATION;
	else if(logLevelNameLower == "debug")
		logLevel = Poco::Message::PRIO_DEBUG;
	else if(logLevelNameLower == "trace")
		logLevel = Poco::Message::PRIO_TRACE;

	return logLevel;
}

void PRPLHTTPServerApplication::initializeLogging()
{
	const std::string logLevelName = config().getString("logging.level", "information");
	// const Poco::UInt32 logLevel = config().getInt("logging.level", Poco::Message::PRIO_INFORMATION);

	Poco::Logger::root().setLevel(logLevelName);
//	Poco::Logger::root().setLevel(Poco::Message::PRIO_TRACE);

/*
	Poco::Logger::root().information("info msg 1");
	Poco::Logger::root().debug("debug msg 0");
	Poco::Logger::root().debug("debug msg 1");
*/
	//Simple file Log
	Poco::SimpleFileChannel* pSimpleFileChannel = new Poco::SimpleFileChannel("./prpld.log");
	pSimpleFileChannel->open();
	pSimpleFileChannel->setProperty("rotation", "10 M");
	// pSimpleFileChannel->setProperty("purge-age", "2 months");

	Poco::ConsoleChannel* pConsoleChannel = new Poco::ConsoleChannel();

	Poco::SplitterChannel* pSplitterChannel = new Poco::SplitterChannel();
	pSplitterChannel->addChannel(pSimpleFileChannel);
	pSplitterChannel->addChannel(pConsoleChannel);

	Poco::PatternFormatter* pPatternFormatter = new Poco::PatternFormatter();
	//pPatternFormatter->setProperty(Poco::PatternFormatter::PROP_PATTERN, "%Y%m%d %H:%M:%S %q %T [%I] %s: %t");
	pPatternFormatter->setProperty(Poco::PatternFormatter::PROP_PATTERN, "%Y%m%d %H:%M:%S %q [%I] %s: %t");

	Poco::FormattingChannel* pFormattingChannel = new Poco::FormattingChannel(pPatternFormatter, pSplitterChannel);

	Poco::Logger::root().setChannel("", pFormattingChannel);
	Poco::Logger::root().setLevel(logLevelName);

	poco_information(Poco::Logger::root(), "---------------------------------------------------");
	poco_fatal_f1(Poco::Logger::root(), "Log level set to %d", Poco::Logger::root().getLevel());
}

bool PRPLHTTPServerApplication::connectDB()
{
	Poco::Data::MySQL::Connector::registerConnector();

    _pDbSessionPool = new Poco::Data::SessionPool("MySQL", "host=localhost;port=3306;db=PRPL;user=PRPL;password=parklife;compress=true;auto-reconnect=true");

    Poco::Data::Session session = _pDbSessionPool->get();

	// Poco::Data::Session session("MySQL", "host=localhost;port=3306;db=PRPL;user=PRPL;password=parklife;compress=true;auto-reconnect=true");

	// Check Schema version is valid
	Param param;
	Poco::Data::Statement select(session);
	select << "SELECT NAME, VALUE FROM PARAM WHERE NAME = 'SCHEMA_VERSION'",
		   Poco::Data::Keywords::into(param.name),
		   Poco::Data::Keywords::into(param.value),
		   Poco::Data::Keywords::range(0, 1); //  iterate over result set one row at a time

	SchemaVersion schemaVersion = {0, 0, 0, 0};
	std::string schemaVersionStr;
	while (!select.done())
	{
		select.execute();

		schemaVersionStr = param.value;
		Poco::StringTokenizer stringTokenizer(schemaVersionStr, ".");
		Poco::StringTokenizer::Iterator iter;
		unsigned int tokenCount = 0;
		for(iter = stringTokenizer.begin(); iter != stringTokenizer.end(); ++iter)
		{
			switch (tokenCount)
			{
			case 0:
				Poco::NumberParser::tryParseUnsigned(*iter, schemaVersion.major);
				break;
			case 1:
				Poco::NumberParser::tryParseUnsigned(*iter, schemaVersion.minor);
				break;
			case 2:
				Poco::NumberParser::tryParseUnsigned(*iter, schemaVersion.release);
				break;
			case 3:
				Poco::NumberParser::tryParseUnsigned(*iter, schemaVersion.hotfix);
				break;
			}
			tokenCount++;
		}
	}
	if(schemaVersion.major != _schemaVersion.major || schemaVersion.minor != _schemaVersion.minor)
	{
		poco_error_f4(Poco::Logger::root(), "Schema version %u.%u does not match expected %u.%u",
					  schemaVersion.major, schemaVersion.minor, _schemaVersion.major, _schemaVersion.minor);
		return false;
	}

    _schemaVersion = schemaVersion;

    poco_information_f4(Poco::Logger::root(), "Schema version %u.%u.%u.%u", _schemaVersion.major,
                        _schemaVersion.minor, _schemaVersion.release, _schemaVersion.hotfix);

	return true;
}

PRPLHTTPServerApplication::SchemaVersion PRPLHTTPServerApplication::getSchemaVersion()
{
	return _schemaVersion;
}

int PRPLHTTPServerApplication::main(const std::vector<std::string> &args)
{
	if (!_helpRequested)
	{
		const Poco::UInt16 port = config().getInt("http.port", 8080);

		initializeLogging();

		poco_information(Poco::Logger::root(), _appName + " starting. (built on " __DATE__ " " __TIME__ ")");

		if(!connectDB())
		{
			return Application::EXIT_DATAERR;
		}

		Poco::Net::ServerSocket socket(port);

		Poco::Net::HTTPServerParams *pParams = new Poco::Net::HTTPServerParams();
		pParams->setMaxQueued(100);
		pParams->setMaxThreads(16);

		Poco::Net::HTTPServer server(new HandlerFactory(), socket, pParams);

		server.start();

		poco_information_f1(Poco::Logger::root(), "HTTP listening on port %hu", port);

        startResultsHavester();

		waitForTerminationRequest();

		poco_information(Poco::Logger::root(), "Stop request received.");
		_stopping = true;

		poco_information(Poco::Logger::root(), "Stopping results harvester...");
        _pResultsHarvesterTimer->stop();
        delete _pResultsHarvesterTimer;

		poco_information(Poco::Logger::root(), "Stopping HTTP server...");
		server.stop();
	}

	return Application::EXIT_OK;
}


void PRPLHTTPServerApplication::startResultsHavester()
{
    const unsigned long resultsSleepBetweenRuns = config().getInt("results.sleep-between-runs-seconds", 360);

    _pResultsHarvesterTimer = new Poco::Timer(1000, resultsSleepBetweenRuns * 1000);

    ResultsControllerTimer resultsControllerTimer;
    _pResultsHarvesterTimer->start(Poco::TimerCallback<ResultsControllerTimer>(resultsControllerTimer, &ResultsControllerTimer::onTimer));
}
