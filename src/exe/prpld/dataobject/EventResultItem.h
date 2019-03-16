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
#ifndef EventResultItem_INCLUDED
#define EventResultItem_INCLUDED

#include <Poco/DateTime.h>
#include <Poco/Nullable.h>

#include "../Common.h"

#include <vector>

class EventResultItem
{
public:
	EventResultItem();
	EventResultItem(const unsigned long _ID, const unsigned long eventResultID, const unsigned long position,
                    Poco::Nullable<unsigned long> genderPosition, Poco::Nullable<std::string> gender, Poco::Nullable<unsigned long> athleteID,
                    Poco::Nullable<unsigned long> durationSecs);

public:
    unsigned long ID;
	unsigned long eventResultID;
	unsigned long position;
	Poco::Nullable<unsigned long> genderPosition;
	Poco::Nullable<std::string> gender;
	Poco::Nullable<unsigned long> athleteID;
	Poco::Nullable<unsigned long> durationSecs;

public:
    Poco::Timespan getDurationTimespan() const;
};

typedef std::vector<EventResultItem*> EventResultItems;

#endif // EventResultItem_INCLUDED
