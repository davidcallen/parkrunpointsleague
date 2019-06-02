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
#include "EventLeagueItem.h"

EventLeagueItem::EventLeagueItem()
	: ID(0), eventLeagueID(0), position(0), genderPosition(0),
	athleteID(0), points(0), runCount(0)
{

}

EventLeagueItem::EventLeagueItem(const unsigned long _ID, const unsigned long _eventLeagueID,
								const unsigned long _athleteID, const std::string& _gender,
								const unsigned long _points, const unsigned long _runCount)
	: ID(_ID), eventLeagueID(_eventLeagueID), position(0), genderPosition(0),
	athleteID(_athleteID), gender(_gender), points(_points), runCount(_runCount)
{

}

STATIC unsigned long EventLeagueItem::calculatePoints(const unsigned long genderPosition, const unsigned long maxPoints)
{
	unsigned long points = 0;
	if(genderPosition < maxPoints)
	{
		points = maxPoints - genderPosition + 1;
		if(points < 0)
		{
			points = 0;
		}
	}
	return points;
}
