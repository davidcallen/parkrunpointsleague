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
#ifndef EventDataModel_INCLUDED
#define EventDataModel_INCLUDED

#include <Poco/DateTime.h>
#include <Poco/Data/Session.h>

#include "../Common.h"
#include "../dataobject/Event.h"

class EventDataModel
{
public:
	static bool fetch(const std::string& name, Event& event);
	static bool fetch(Poco::Data::Session& dbSession, const std::string& name, Event& event);

    static bool fetch(Events& events);
    static bool fetch(Poco::Data::Session& dbSession, Events& events);


    static bool update(const Event& event);
    static bool update(Poco::Data::Session& dbSession, const Event& event);

    static void free(Events& events);
    static void freeEvent(Event* pEvent);
};

#endif // EventDataModel_INCLUDED
