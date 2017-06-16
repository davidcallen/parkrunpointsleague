#ifndef Cache_INCLUDED
#define Cache_INCLUDED

#include "Common.h"

class Cache
{
public:
    Cache();

protected:
	bool checkFileExists(const std::string& fileNameAndPath);
	bool getFromFile(const std::string& fileNameAndPath, std::string& contents);
    bool saveToFile(const std::string& fileNameAndPath, const std::string& contents);

protected:
    std::string _dataResultsPath;
};

#endif // Cache_INCLUDED
