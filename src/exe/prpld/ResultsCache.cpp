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
#include "ResultsCache.h"

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

ResultsCache::ResultsCache() : Cache()
{
}

bool ResultsCache::checkExists(const std::string& eventName, const unsigned long resultNumber)
{
	poco_assert_dbg(!eventName.empty());
	poco_assert_dbg(resultNumber != 0);

	std::string fileNameAndPath = getFilenameAndPath(eventName, resultNumber);

	return checkFileExists(fileNameAndPath);
}

bool ResultsCache::get(const std::string& eventName, const unsigned long resultNumber, std::string& html)
{
	poco_assert_dbg(!eventName.empty());
	poco_assert_dbg(resultNumber != 0);

	std::string fileNameAndPath = getFilenameAndPath(eventName, resultNumber);
	Poco::File file(fileNameAndPath);

	return getFromFile(fileNameAndPath, html);
}

bool ResultsCache::save(const std::string& eventName, const unsigned long resultNumber, const std::string& html)
{
	poco_assert_dbg(!eventName.empty());
	poco_assert_dbg(resultNumber != 0);

	std::string filePath = getEventDataPath(eventName);
	Poco::File file(filePath);
	file.createDirectories();

	std::string fileNameAndPath = getFilenameAndPath(eventName, resultNumber);

	return saveToFile(fileNameAndPath, html);
}

std::string ResultsCache::getFilenameAndPath(const std::string& eventName, const unsigned long resultNumber)
{
	poco_assert_dbg(!eventName.empty());
	poco_assert_dbg(resultNumber != 0);

	return getEventDataPath(eventName) + "/" + getFilename(resultNumber);
}

std::string ResultsCache::getEventDataPath(const std::string& eventName)
{
	poco_assert_dbg(!eventName.empty());

	return _dataResultsPath + eventName;
}

std::string ResultsCache::getFilename(const unsigned long resultNumber)
{
	poco_assert_dbg(resultNumber != 0);

	return "results-" + Poco::NumberFormatter::format0(resultNumber, 6) + ".html";
}



