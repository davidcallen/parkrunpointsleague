#include "Cache.h"

#include <Poco/String.h>
#include <Poco/File.h>

#include <Poco/DateTime.h>
#include <Poco/DateTimeFormatter.h>
#include <Poco/DateTimeFormat.h>
#include <Poco/DateTimeParser.h>
#include <Poco/Timespan.h>

#include <Poco/Logger.h>

#include <Poco/StreamCopier.h>
#include <Poco/NullStream.h>

#include <Poco/NumberParser.h>
#include <Poco/NumberFormatter.h>

#include <Poco/Util/Application.h>

#include <gumbo.h>

#include <iostream>
#include <fstream>
#include <sstream>
#include <memory>
#include <algorithm>

Cache::Cache()
{
	_dataResultsPath = Poco::Util::Application::instance().config().getString("data.results.path", "../data/results/");
}

bool Cache::checkFileExists(const std::string& fileNameAndPath)
{
    poco_assert_dbg(!fileNameAndPath.empty());

	Poco::File file(fileNameAndPath);

	return file.exists();
}

bool Cache::getFromFile(const std::string& fileNameAndPath, std::string& contents)
{
    poco_assert_dbg(!fileNameAndPath.empty());

	Poco::File file(fileNameAndPath);

	if(file.exists())
	{
		std::ifstream ifs(fileNameAndPath.c_str(), std::ofstream::in | std::ofstream::binary);

		std::stringstream fileDataStream(std::ios_base::in | std::ios_base::out);

		Poco::StreamCopier::copyStream(ifs, fileDataStream);
		ifs.close();

		contents = fileDataStream.str();

		return true;
	}

	return false;
}

bool Cache::saveToFile(const std::string& fileNameAndPath, const std::string& contents)
{
    poco_assert_dbg(!fileNameAndPath.empty());

    std::ofstream ofs(fileNameAndPath.c_str(), std::ofstream::out | std::ofstream::binary);
    ofs << contents;
    //Poco::StreamCopier::copyStream(responseStream, ofs);
    ofs.close();

    return true;
}
