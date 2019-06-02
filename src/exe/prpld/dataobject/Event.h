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
#ifndef Event_INCLUDED
#define Event_INCLUDED

#include <Poco/Nullable.h>
#include <Poco/DateTime.h>

#include "../Common.h"

#include <vector>

class Event
{
public:
	Event();
	Event(const std::string& p_name, const std::string& p_title, const Poco::Nullable<Poco::DateTime>& p_birthday = Poco::NULL_GENERIC);

//	virtual unsigned long getBirthdayMonth();
//	virtual unsigned long getBirthdayDay();

public:
	unsigned long ID;
	std::string name;
	std::string title;
	Poco::Nullable<Poco::DateTime> birthday;

/*	std::string birthday;

protected:
	virtual void splitBirthday();

protected:
	unsigned long _birthdayMonth;
	unsigned long _birthdayDay;
	*/
};

typedef std::vector<Event*> Events;

#endif // Event_INCLUDED
