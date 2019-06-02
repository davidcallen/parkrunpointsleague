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
#ifndef EventLeagueItem_INCLUDED
#define EventLeagueItem_INCLUDED

#include <Poco/DateTime.h>
#include <Poco/Nullable.h>

#include "../Common.h"

#include <vector>
#include <map>

class EventLeagueItem
{
public:
	EventLeagueItem();
	EventLeagueItem(const unsigned long _ID, const unsigned long _eventLeagueID,
					const unsigned long _athleteID, const std::string& _gender,
					const unsigned long _points, const unsigned long _runCount);

public:
	static unsigned long calculatePoints(const unsigned long genderPosition, const unsigned long maxPoints);

public:
	unsigned long ID;
	unsigned long eventLeagueID;
	unsigned long position;
	unsigned long genderPosition;
	std::string gender;
	unsigned long athleteID;
	unsigned long points;
	unsigned long runCount;
};

typedef std::vector<EventLeagueItem*> EventLeagueItems;
typedef std::map<const unsigned long, EventLeagueItem*> EventLeagueItemsMapByAthlete;


#endif // EventLeagueItem_INCLUDED
