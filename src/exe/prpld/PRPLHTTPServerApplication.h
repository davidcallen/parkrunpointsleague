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
	void cleanup();

	struct Version
	{
		unsigned int major;
		unsigned int minor;
		unsigned int release;
		unsigned int hotfix;
	};

	Poco::Data::SessionPool* getDbSessionPool();
	// Poco::Data::Session* getDbSession();

	bool isStopping() const;
	const std::string getHostName() const;
	const Version getVersion() const;
	const std::string getVersionString() const;
	const Version getSchemaVersion() const;

protected:
	void initialize(Application& self);

//	void uninitialize();

	void defineOptions(Poco::Util::OptionSet& options);

	void handleHelp(const std::string& name, const std::string& value);

	int getLogLevel(const std::string& logLevelName);

	void initializeLogging();

	bool connectDB();

	int main(const std::vector<std::string> &args);
	void startResultsHarvester();
	void stopResultsHarvester();

private:
	static PRPLHTTPServerApplication* _pInstance;

private:
	bool _helpRequested;
	std::string _appName;
	std::string _hostName;
	Version _version;
	Version _schemaVersion;
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
