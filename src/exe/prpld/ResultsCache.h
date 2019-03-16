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
