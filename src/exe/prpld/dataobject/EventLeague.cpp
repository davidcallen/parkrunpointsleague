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
#include "EventLeague.h"

EventLeague::EventLeague()
	: ID(0), eventID(0), year(0), latestEventResultID(0)
{
}

EventLeague::EventLeague(unsigned long _ID, unsigned long _eventID, unsigned long _year, unsigned long _latestEventResultID)
	: ID(_ID), eventID(_eventID), year(_year), latestEventResultID(_latestEventResultID)
{
}
