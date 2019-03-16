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
#include "EventLeagueDataModel.h"
#include "../PRPLHTTPServerApplication.h"

#include <Poco/Util/Application.h>
#include <Poco/Data/Session.h>
#include <Poco/DateTime.h>
#include <Poco/Timespan.h>

#include <algorithm>
#include <utility>

STATIC bool EventLeagueDataModel::fetch(const unsigned long eventID, EventLeagues& eventLeagues)
{
    Poco::Data::Session dbSession = PRPLHTTPServerApplication::instance().getDbSessionPool()->get();

    return fetch(dbSession, eventID, eventLeagues);
}

STATIC bool EventLeagueDataModel::fetch(Poco::Data::Session& dbSession, const unsigned long eventID, EventLeagues& eventLeagues)
{
    bool result = true;

    eventLeagues.clear();

    EventLeague tmpEventLeague;

	Poco::Data::Statement dbStmt(dbSession);
	dbStmt << "select ID, EVENT_ID, YEAR, LATEST_EVENT_RESULT_ID from EVENT_LEAGUE where EVENT_ID = ? ORDER BY YEAR DESC",
		   Poco::Data::Keywords::into(tmpEventLeague.ID),
		   Poco::Data::Keywords::into(tmpEventLeague.eventID),
		   Poco::Data::Keywords::into(tmpEventLeague.year),
		   Poco::Data::Keywords::into(tmpEventLeague.latestEventResultID),
		   Poco::Data::Keywords::useRef(eventID),
		   Poco::Data::Keywords::range(0, 1);

    while (!dbStmt.done())
    {
        if(dbStmt.execute() > 0)
        {
            EventLeague* pEventLeague = new EventLeague();
            *pEventLeague = tmpEventLeague;

            eventLeagues.push_back(pEventLeague);
        }
    }

    return result;
}

STATIC bool EventLeagueDataModel::fetch(const unsigned long eventID, const unsigned long year, EventLeague& eventLeague)
{
    Poco::Data::Session dbSession = PRPLHTTPServerApplication::instance().getDbSessionPool()->get();

    return fetch(dbSession, eventID, year, eventLeague);
}

STATIC bool EventLeagueDataModel::fetch(Poco::Data::Session& dbSession, const unsigned long eventID, const unsigned long year, EventLeague& eventLeague)
{
    bool result = true;

	Poco::Data::Statement dbStmt(dbSession);
	dbStmt << "select ID, EVENT_ID, YEAR, LATEST_EVENT_RESULT_ID from EVENT_LEAGUE where EVENT_ID = ? AND YEAR = ?",
		   Poco::Data::Keywords::into(eventLeague.ID),
		   Poco::Data::Keywords::into(eventLeague.eventID),
		   Poco::Data::Keywords::into(eventLeague.year),
		   Poco::Data::Keywords::into(eventLeague.latestEventResultID),
		   Poco::Data::Keywords::useRef(eventID),
		   Poco::Data::Keywords::useRef(year),
		   Poco::Data::Keywords::now;

    result = (eventLeague.ID != 0);

    return result;
}

STATIC bool EventLeagueDataModel::update(EventLeague* pEventLeague)
{
    Poco::Data::Session dbSession = PRPLHTTPServerApplication::instance().getDbSessionPool()->get();

    return update(dbSession, pEventLeague);
}

STATIC bool EventLeagueDataModel::update(Poco::Data::Session& dbSession, EventLeague* pEventLeague)
{
    bool result = true;

	Poco::Data::Statement dbStmt(dbSession);
	dbStmt << "update EVENT_LEAGUE set LATEST_EVENT_RESULT_ID = ? where ID = ?",
		   Poco::Data::Keywords::useRef(pEventLeague->latestEventResultID),
		   Poco::Data::Keywords::useRef(pEventLeague->ID),
		   Poco::Data::Keywords::now;

    result = true;

    return result;
}

STATIC bool EventLeagueDataModel::insert(EventLeague* pEventLeague)
{
    Poco::Data::Session dbSession = PRPLHTTPServerApplication::instance().getDbSessionPool()->get();

    return insert(dbSession, pEventLeague);
}

STATIC bool EventLeagueDataModel::insert(Poco::Data::Session& dbSession, EventLeague* pEventLeague)
{
    bool result = true;

	Poco::Data::Statement dbStmt(dbSession);
	dbStmt << "insert into EVENT_LEAGUE (EVENT_ID, YEAR, LATEST_EVENT_RESULT_ID) values (?, ?, ?)",
		   Poco::Data::Keywords::useRef(pEventLeague->eventID),
		   Poco::Data::Keywords::useRef(pEventLeague->year),
		   Poco::Data::Keywords::useRef(pEventLeague->latestEventResultID),
		   Poco::Data::Keywords::now;

    result = true;

    return result;
}

STATIC bool EventLeagueDataModel::remove(const unsigned long eventID)
{
    Poco::Data::Session dbSession = PRPLHTTPServerApplication::instance().getDbSessionPool()->get();

    return remove(dbSession, eventID);
}

STATIC bool EventLeagueDataModel::remove(Poco::Data::Session& dbSession, const unsigned long eventID)
{
    bool result = true;

	Poco::Data::Statement dbStmt(dbSession);
	dbStmt << "delete from EVENT_LEAGUE where EVENT_ID = ?",
		   Poco::Data::Keywords::useRef(eventID),
		   Poco::Data::Keywords::now;

    result = true;

    return result;
}

STATIC bool EventLeagueDataModel::remove(Poco::Data::Session& dbSession, const unsigned long eventID, const unsigned long leagueYear)
{
    bool result = true;

	Poco::Data::Statement dbStmt(dbSession);
	dbStmt << "delete from EVENT_LEAGUE where EVENT_ID = ? and YEAR = ?",
		   Poco::Data::Keywords::useRef(eventID),
		   Poco::Data::Keywords::useRef(leagueYear),
		   Poco::Data::Keywords::now;

    result = true;

    return result;
}

STATIC void EventLeagueDataModel::free(EventLeagues& eventLeagues)
{
    std::for_each(eventLeagues.begin(), eventLeagues.end(), EventLeagueDataModel::freeEventLeague);
    eventLeagues.clear();
}

STATIC void EventLeagueDataModel::freeEventLeague(EventLeague* pEventLeague)
{
    if(pEventLeague != NULL)
    {
        delete pEventLeague;
    }
}

STATIC void EventLeagueDataModel::freeEventLeaguePair(std::pair<const unsigned long, EventLeague*>& eventLeaguePair)
{
    if(eventLeaguePair.second != NULL)
    {
        delete eventLeaguePair.second;
    }
}

