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
#include "EventHistoryCache.h"

#include <Poco/String.h>
#include <Poco/Logger.h>
#include <Poco/Util/Application.h>
#include <Poco/File.h>

EventHistoryCache::EventHistoryCache() : Cache()
{
}

bool EventHistoryCache::checkExists(const std::string& eventName)
{
    poco_assert_dbg(!eventName.empty());

	std::string fileNameAndPath = getFilenameAndPath(eventName);

	return checkFileExists(fileNameAndPath);
}

bool EventHistoryCache::get(const std::string& eventName, std::string& html)
{
    poco_assert_dbg(!eventName.empty());

	std::string fileNameAndPath = getFilenameAndPath(eventName);

	return getFromFile(fileNameAndPath, html);
}

bool EventHistoryCache::save(const std::string& eventName, const std::string& html)
{
    poco_assert_dbg(!eventName.empty());

    std::string filePath = getEventDataPath(eventName);
    Poco::File file(filePath);
    file.createDirectories();

	std::string fileNameAndPath = getFilenameAndPath(eventName);

    return saveToFile(fileNameAndPath, html);
}

std::string EventHistoryCache::getFilenameAndPath(const std::string& eventName)
{
    poco_assert_dbg(!eventName.empty());

	return getEventDataPath(eventName) + "/history.html";
}

std::string EventHistoryCache::getEventDataPath(const std::string& eventName)
{
    poco_assert_dbg(!eventName.empty());

	return _dataResultsPath + eventName;
}

