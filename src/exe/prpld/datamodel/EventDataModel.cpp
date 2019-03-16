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
#include "EventDataModel.h"
#include "../PRPLHTTPServerApplication.h"

#include <Poco/Util/Application.h>
#include <Poco/Data/Session.h>
#include <Poco/DateTime.h>


STATIC bool EventDataModel::fetch(const std::string& name, Event& event)
{
    Poco::Data::Session dbSession = PRPLHTTPServerApplication::instance().getDbSessionPool()->get();

    return fetch(dbSession, name, event);
}

STATIC bool EventDataModel::fetch(Poco::Data::Session& dbSession, const std::string& name, Event& event)
{
    bool result = true;

    event.ID = 0;

	Poco::Data::Statement select(dbSession);
	select << "select ID, NAME, TITLE, BIRTHDAY from EVENT where NAME = ?",
		   Poco::Data::Keywords::into(event.ID),
		   Poco::Data::Keywords::into(event.name),
		   Poco::Data::Keywords::into(event.title),
		   Poco::Data::Keywords::into(event.birthday),
		   Poco::Data::Keywords::useRef(name),
		   Poco::Data::Keywords::now;

    result = (event.ID != 0);

    return result;
}

STATIC bool EventDataModel::fetch(Events& events)
{
    Poco::Data::Session dbSession = PRPLHTTPServerApplication::instance().getDbSessionPool()->get();

    return fetch(dbSession, events);
}

STATIC bool EventDataModel::fetch(Poco::Data::Session& dbSession, Events& events)
{
    bool result = true;

    Event tmpEvent;

	Poco::Data::Statement dbStmt(dbSession);
	dbStmt << "select ID, NAME, TITLE, BIRTHDAY from EVENT order by NAME DESC",
		   Poco::Data::Keywords::into(tmpEvent.ID),
		   Poco::Data::Keywords::into(tmpEvent.name),
		   Poco::Data::Keywords::into(tmpEvent.title),
		   Poco::Data::Keywords::into(tmpEvent.birthday),
		   Poco::Data::Keywords::range(0, 1);

	while (!dbStmt.done())
	{
        if(dbStmt.execute() > 0)
        {
            Event* pEvent = new Event;
            *pEvent= tmpEvent;

            events.push_back(pEvent);
        }
	}

    return result;
}

STATIC bool EventDataModel::update(const Event& event)
{
    Poco::Data::Session dbSession = PRPLHTTPServerApplication::instance().getDbSessionPool()->get();

    return update(dbSession, event);
}

STATIC bool EventDataModel::update(Poco::Data::Session& dbSession, const Event& event)
{
    bool result = true;

	Poco::Data::Statement dbStmt(dbSession);
	dbStmt << "update EVENT set NAME = ?, TITLE = ?, BIRTHDAY = ? where ID = ?",
		   Poco::Data::Keywords::useRef(event.name),
		   Poco::Data::Keywords::useRef(event.title),
		   Poco::Data::Keywords::useRef(event.birthday.value()),
		   Poco::Data::Keywords::useRef(event.ID),
		   Poco::Data::Keywords::now;

    result = true;

    return result;
}

STATIC void EventDataModel::free(Events& events)
{
    std::for_each(events.begin(), events.end(), EventDataModel::freeEvent);
    events.clear();
}

STATIC void EventDataModel::freeEvent(Event* pEvent)
{
    if(pEvent != NULL)
    {
        delete pEvent;
    }
}
