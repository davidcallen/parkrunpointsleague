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

