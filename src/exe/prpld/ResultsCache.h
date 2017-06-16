#ifndef ResultsCache_INCLUDED
#define ResultsCache_INCLUDED

#include "Cache.h"
#include "Common.h"

class ResultsCache : Cache
{
public:
    ResultsCache();

public:
	bool checkExists(const std::string& eventName, const unsigned long resultNumber);
	bool get(const std::string& eventName, const unsigned long resultNumber, std::string& html);
    bool save(const std::string& eventName, const unsigned long resultNumber, const std::string& html);

protected:
    std::string getFilenameAndPath(const std::string& eventName, const unsigned long resultNumber);
    std::string getEventDataPath(const std::string& eventName);
    std::string getFilename(const unsigned long resultNumber);
};

#endif // ResultsCache_INCLUDED
