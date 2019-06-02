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
