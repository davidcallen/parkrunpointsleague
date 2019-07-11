/* 
Park Run Points League website

Copyright (C) 2017  David C Allen

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/
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
#include <Poco/Environment.h>

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
	_version.major = 0;
	_version.minor = 1;
	_version.release = 0;
	_version.hotfix = 1;

	_schemaVersion.major = 0;
	_schemaVersion.minor = 1;
	_schemaVersion.release = 0;
	_schemaVersion.hotfix = 1;

	_pInstance = this;
}

VIRTUAL PRPLHTTPServerApplication::~PRPLHTTPServerApplication()
{
	_pInstance = NULL;
	cleanup();
}

void PRPLHTTPServerApplication::cleanup()
{
	if(_pDbSessionPool != NULL)
	{
		poco_information(Poco::Logger::root(), "Shutting down DB Session Pool");
		_pDbSessionPool->shutdown();
		delete _pDbSessionPool;
		_pDbSessionPool= NULL;
	}
	Poco::Logger::root().shutdown();
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

const std::string PRPLHTTPServerApplication::getHostName() const
{
	return _hostName;
}

const PRPLHTTPServerApplication::Version PRPLHTTPServerApplication::getVersion() const
{
	return _version;
}

const std::string PRPLHTTPServerApplication::getVersionString() const
{
	std::string versionString;
	Poco::NumberFormatter::append(versionString, _version.major);
	versionString += ".";
	Poco::NumberFormatter::append(versionString, _version.minor);
	versionString += ".";
	Poco::NumberFormatter::append(versionString, _version.release);
	versionString += ".";
	Poco::NumberFormatter::append(versionString, _version.hotfix);
	
	return versionString;
}

const PRPLHTTPServerApplication::Version PRPLHTTPServerApplication::getSchemaVersion() const
{
	return _schemaVersion;
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
	std::string logLevelName = config().getString("logging.level", "information");
	logLevelName = Poco::Environment::get("PRPL_LOGGING_LEVEL", logLevelName);
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
	pPatternFormatter->setProperty(Poco::PatternFormatter::PROP_PATTERN, "{\"log\":\"%Y%m%d %H:%M:%S %q %T [%I] %s: %t\", \"severity\":\"%p\", \"stream\":\"stderr\", ,\"time\":\"%Y-%m-%dT%H:%M:%S.%F%z\"}");

	// {"log":"2014/09/25 21:15:03 Got request with path wombat\\n", "stream":"stderr", "time":"2014-09-25T21:15:03.499185026Z"}

	Poco::FormattingChannel* pFormattingChannel = new Poco::FormattingChannel(pPatternFormatter, pSplitterChannel);

	Poco::Logger::root().setChannel("", pFormattingChannel);
	Poco::Logger::root().setLevel(logLevelName);

	poco_information(Poco::Logger::root(), "---------------------------------------------------");
	poco_fatal_f1(Poco::Logger::root(), "Log level set to %d", Poco::Logger::root().getLevel());
}

bool PRPLHTTPServerApplication::connectDB()
{
	Poco::Data::MySQL::Connector::registerConnector();

	std::string dbConnectString = config().getString("database.connection-string", "");
	dbConnectString = Poco::Environment::get("PRPL_DATABASE_CONNECT_STRING", dbConnectString);
	if(dbConnectString.empty())
	{
		std::string databaseName = config().getString("database.name", "PRPL");
		databaseName = Poco::Environment::get("PRPL_DATABASE_NAME", databaseName);
		std::string databaseHost = config().getString("database.host", "localhost");
		databaseHost = Poco::Environment::get("PRPL_DATABASE_HOST", databaseHost);
		std::string databasePort = config().getString("database.port", "3306");
		databasePort = Poco::Environment::get("PRPL_DATABASE_PORT", databasePort);
		std::string databaseUser = config().getString("database.user", "PRPL");
		databaseUser = Poco::Environment::get("PRPL_DATABASE_USER", databaseUser);
		std::string databasePassword = config().getString("database.password", "");
		databasePassword = Poco::Environment::get("PRPL_DATABASE_PWD", databasePassword);

		dbConnectString = "host=";
		dbConnectString += databaseHost;
		dbConnectString += ";port=";
		dbConnectString += databasePort;
		dbConnectString += ";db=";
		dbConnectString += databaseName;
		dbConnectString += ";user=";
		dbConnectString += databaseUser;
		dbConnectString += ";password=";
		dbConnectString += databasePassword;
		dbConnectString += ";compress=true;auto-reconnect=true";
	}
	poco_information_f1(Poco::Logger::root(), "Create database session pool using '%s'", dbConnectString);

	_pDbSessionPool = new Poco::Data::SessionPool("MySQL", dbConnectString);

	// Check if we can connect
	try
	{
		poco_information(Poco::Logger::root(), "Get database session");
		Poco::Data::Session session = _pDbSessionPool->get();
	}
	catch (Poco::Exception& e)
	{
		poco_error(Poco::Logger::root(), "Failed to connected to database");
		poco_warning(Poco::Logger::root(), "Failed to check database schema version");

		return false;
	}

	Poco::Data::Session session = _pDbSessionPool->get();
	poco_information(Poco::Logger::root(), "Connected to database");

	// Check Schema version is valid
	poco_information_f2(Poco::Logger::root(), "Checking Schema Version. Expecting %u.%u",
						_schemaVersion.major, _schemaVersion.minor);
	Param param;
	Poco::Data::Statement select(session);
	select << "SELECT NAME, VALUE FROM PARAM WHERE NAME = 'SCHEMA_VERSION'",
		   Poco::Data::Keywords::into(param.name),
		   Poco::Data::Keywords::into(param.value),
		   Poco::Data::Keywords::range(0, 1); //  iterate over result set one row at a time

	Version schemaVersion = {0, 0, 0, 0};
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

int PRPLHTTPServerApplication::main(const std::vector<std::string> &args)
{
	if (!_helpRequested)
	{
		Poco::UInt16 port = config().getInt("http.port", 8080);
		if(Poco::Environment::has("PRPL_HTTP_PORT"))
		{
			port = Poco::NumberParser::parse(Poco::Environment::get("PRPL_HTTP_PORT"));
		}

		initializeLogging();

		char hostName[1024];
		if(gethostname(hostName, 1024) == 0)
		{
			_hostName = std::string(hostName);
		}

		poco_information(Poco::Logger::root(), _appName + " starting v0.1.0.0 (built on " __DATE__ " " __TIME__ ") on host : " + _hostName);

		connectDB();

		Poco::Net::ServerSocket socket(port);

		Poco::Net::HTTPServerParams *pParams = new Poco::Net::HTTPServerParams();
		pParams->setMaxQueued(100);
		pParams->setMaxThreads(16);

		Poco::Net::HTTPServer server(new HandlerFactory(), socket, pParams);

		server.start();

		poco_information_f1(Poco::Logger::root(), "HTTP listening on port %hu", port);

		startResultsHarvester();
		
		waitForTerminationRequest();

		poco_information(Poco::Logger::root(), "Stop request received.");
		_stopping = true;

		poco_information(Poco::Logger::root(), "Stopping results harvester...");
		stopResultsHarvester();

		poco_information(Poco::Logger::root(), "Stopping HTTP server...");

		poco_information(Poco::Logger::root(), "Cleaning up ...");
		cleanup();
		server.stop();
	}

	poco_information(Poco::Logger::root(), "Shutting down ...");

	return Application::EXIT_OK;
}


void PRPLHTTPServerApplication::startResultsHarvester()
{
	bool resultsScrapingEnabled = config().getBool("results.scraping-enabled", true);
	if(Poco::Environment::has("PRPL_RESULTS_SCRAPING_ENABLED"))
	{
		resultsScrapingEnabled = Poco::NumberParser::parseBool(Poco::Environment::get("PRPL_RESULTS_SCRAPING_ENABLED"));
	}
	if(!resultsScrapingEnabled)
	{
		return;
	}
	
	const unsigned long resultsSleepBetweenRuns = config().getInt("results.sleep-between-runs-seconds", 360);

	_pResultsHarvesterTimer = new Poco::Timer(1000, resultsSleepBetweenRuns * 1000);

	ResultsControllerTimer resultsControllerTimer;
	_pResultsHarvesterTimer->start(Poco::TimerCallback<ResultsControllerTimer>(resultsControllerTimer, &ResultsControllerTimer::onTimer));
}

void PRPLHTTPServerApplication::stopResultsHarvester()
{
	if(_pResultsHarvesterTimer != NULL)
	{
		_pResultsHarvesterTimer->stop();
		delete _pResultsHarvesterTimer;
	}
}
