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
#include "Event.h"

Event::Event()
	: ID(0), birthday(Poco::NULL_GENERIC)
{
}

Event::Event(const std::string& p_name, const std::string& p_title, const Poco::Nullable<Poco::DateTime>& p_birthday)
	: ID(0), name(p_name), title(p_title), birthday(p_birthday)
{
}

/*
VIRTUAL unsigned long Event::getBirthdayMonth()
{
    if(_birthdayMonth == 0)
    {
        splitBirthday();
    }

    return _birthdayMonth;
}

VIRTUAL unsigned long Event::getBirthdayDay()
{
    if(_birthdayDay == 0)
    {
        splitBirthday();
    }

    return _birthdayDay;
}

VIRTUAL void Event::splitBirthday()
{
    Poco::StringTokenizer tokenizer(birthday, "-");
    if(tokenizer.size() > 0)
    {
        _birthdayMonth = Poco::NumberParser(tokenizer[0]);
    }
    if(tokenizer.size() > 1)
    {
        _birthdayDay = Poco::NumberParser(tokenizer[1]);
    }
}

*/
