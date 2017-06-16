#ifndef EventHistoryCache_INCLUDED
#define EventHistoryCache_INCLUDED

#include "Common.h"
#include "Cache.h"

class EventHistoryCache : public Cache
{
public:
    EventHistoryCache();

public:
	bool checkExists(const std::string& eventName);
	bool get(const std::string& eventName, std::string& html);
    bool save(const std::string& eventName, const std::string& html);

protected:
    std::string getFilenameAndPath(const std::string& eventName);
    std::string getEventDataPath(const std::string& eventName);
//    std::string getFilename();

};

#endif // EventHistoryCache_INCLUDED
