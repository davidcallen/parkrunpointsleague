#ifndef PRPLHTTPServerApplication_INCLUDED
#define PRPLHTTPServerApplication_INCLUDED

#include "Common.h"

#include <Poco/Util/ServerApplication.h>
#include <Poco/Util/Option.h>
#include <Poco/Util/OptionSet.h>

#include <Poco/Data/SessionPool.h>


class PRPLHTTPServerApplication : public Poco::Util::ServerApplication
{
public:
	static PRPLHTTPServerApplication& instance();

public:
	PRPLHTTPServerApplication();

	virtual ~PRPLHTTPServerApplication();

	struct SchemaVersion
	{
		unsigned int major;
		unsigned int minor;
		unsigned int release;
		unsigned int hotfix;
	};

	Poco::Data::SessionPool* getDbSessionPool();

	bool isStopping() const;


protected:
	void initialize(Application& self);

//	void uninitialize();

	void defineOptions(Poco::Util::OptionSet& options);

	void handleHelp(const std::string& name, const std::string& value);

	int getLogLevel(const std::string& logLevelName);

	void initializeLogging();

	bool connectDB();

	SchemaVersion getSchemaVersion();

	int main(const std::vector<std::string> &args);
    void startResultsHavester();

private:
	static PRPLHTTPServerApplication* _pInstance;

private:
	bool _helpRequested;
	std::string _appName;
	SchemaVersion _schemaVersion;
    Poco::Data::SessionPool* _pDbSessionPool;
    bool _stopping;
    Poco::Timer* _pResultsHarvesterTimer;
};


STATIC inline PRPLHTTPServerApplication& PRPLHTTPServerApplication::instance()
{
	// return Application()::instance();
	poco_check_ptr (_pInstance);
	return *_pInstance;
}

#endif // PRPLHTTPServerApplication_INCLUDED
