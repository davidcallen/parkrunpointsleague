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
#include "EventLeagueItemDataModel.h"
#include "../PRPLHTTPServerApplication.h"

#include <Poco/Util/Application.h>
#include <Poco/Data/Session.h>
#include <Poco/DateTime.h>
#include <Poco/Timespan.h>

#include <algorithm>
#include <utility>

STATIC bool EventLeagueItemDataModel::fetch(const unsigned long eventLeagueID, const std::string& orderByFieldName, EventLeagueItems& eventLeagueItems)
{
	Poco::Data::Session dbSession = PRPLHTTPServerApplication::instance().getDbSessionPool()->get();

	return fetch(dbSession, eventLeagueID, orderByFieldName, eventLeagueItems);
}

STATIC bool EventLeagueItemDataModel::fetch(Poco::Data::Session& dbSession, const unsigned long eventLeagueID,
											const std::string& orderByFieldName, EventLeagueItems& eventLeagueItems)
{
	bool result = true;

	eventLeagueItems.clear();

	EventLeagueItem tmpEventLeagueItem;

	std::string sqlOrderBy;
	if(!orderByFieldName.empty())
	{
		sqlOrderBy = " ORDER BY " + orderByFieldName + " ASC";
	}
/*
	std::string sqlWhere;
	if(!whereGenderEquals.empty())
	{
		sqlWhere = " AND GENDER in (?) ";
	}
*/
	Poco::Data::Statement dbStmt(dbSession);
	dbStmt << "select ID, EVENT_LEAGUE_ID, POSITION, GENDER_POSITION, GENDER, ATHLETE_ID, POINTS, RUN_COUNT from EVENT_LEAGUE_ITEM where EVENT_LEAGUE_ID = ?" + sqlOrderBy,
		   Poco::Data::Keywords::into(tmpEventLeagueItem.ID),
		   Poco::Data::Keywords::into(tmpEventLeagueItem.eventLeagueID),
		   Poco::Data::Keywords::into(tmpEventLeagueItem.position),
		   Poco::Data::Keywords::into(tmpEventLeagueItem.genderPosition),
		   Poco::Data::Keywords::into(tmpEventLeagueItem.gender),
		   Poco::Data::Keywords::into(tmpEventLeagueItem.athleteID),
		   Poco::Data::Keywords::into(tmpEventLeagueItem.points),
		   Poco::Data::Keywords::into(tmpEventLeagueItem.runCount),
		   Poco::Data::Keywords::useRef(eventLeagueID),
		   Poco::Data::Keywords::range(0, 1);

	while (!dbStmt.done())
	{
		if(dbStmt.execute() > 0)
		{
			EventLeagueItem* pEventLeagueItem = new EventLeagueItem();
			*pEventLeagueItem = tmpEventLeagueItem;

			eventLeagueItems.push_back(pEventLeagueItem);
		}
	}

	return result;
}

STATIC bool EventLeagueItemDataModel::fetch(const unsigned long eventLeagueID, const unsigned long athleteID, EventLeagueItem& eventLeagueItem)
{
	Poco::Data::Session dbSession = PRPLHTTPServerApplication::instance().getDbSessionPool()->get();

	return fetch(dbSession, eventLeagueID, athleteID, eventLeagueItem);
}

STATIC bool EventLeagueItemDataModel::fetch(Poco::Data::Session& dbSession, const unsigned long eventLeagueID, const unsigned long athleteID, EventLeagueItem& eventLeagueItem)
{
	bool result = true;

	Poco::Data::Statement dbStmt(dbSession);
	dbStmt << "select ID, EVENT_LEAGUE_ID, POSITION, GENDER_POSITION, GENDER, ATHLETE_ID, POINTS, RUN_COUNT from EVENT_LEAGUE_ITEM where EVENT_LEAGUE_ID = ? AND ATHLETE_ID = ?",
		Poco::Data::Keywords::into(eventLeagueItem.ID),
		Poco::Data::Keywords::into(eventLeagueItem.eventLeagueID),
		Poco::Data::Keywords::into(eventLeagueItem.position),
		Poco::Data::Keywords::into(eventLeagueItem.genderPosition),
		Poco::Data::Keywords::into(eventLeagueItem.gender),
		Poco::Data::Keywords::into(eventLeagueItem.athleteID),
		Poco::Data::Keywords::into(eventLeagueItem.points),
		Poco::Data::Keywords::into(eventLeagueItem.runCount),
		Poco::Data::Keywords::useRef(eventLeagueID),
		Poco::Data::Keywords::useRef(athleteID),
		Poco::Data::Keywords::now;

	result = (eventLeagueItem.ID != 0);

	return result;
}

STATIC bool EventLeagueItemDataModel::insert(EventLeagueItem* pEventLeagueItem)
{
	Poco::Data::Session dbSession = PRPLHTTPServerApplication::instance().getDbSessionPool()->get();

	return insert(dbSession, pEventLeagueItem);
}

STATIC bool EventLeagueItemDataModel::insert(Poco::Data::Session& dbSession, EventLeagueItem* pEventLeagueItem)
{
	bool result = true;

	Poco::Data::Statement dbStmt(dbSession);
	dbStmt << "insert into EVENT_LEAGUE_ITEM (EVENT_LEAGUE_ID, POSITION, GENDER_POSITION, GENDER, ATHLETE_ID, POINTS, RUN_COUNT) values (?, ?, ?, ?, ?, ?, ?)",
		   Poco::Data::Keywords::useRef(pEventLeagueItem->eventLeagueID),
		   Poco::Data::Keywords::useRef(pEventLeagueItem->position),
		   Poco::Data::Keywords::useRef(pEventLeagueItem->genderPosition),
		   Poco::Data::Keywords::useRef(pEventLeagueItem->gender),
		   Poco::Data::Keywords::useRef(pEventLeagueItem->athleteID),
		   Poco::Data::Keywords::useRef(pEventLeagueItem->points),
		   Poco::Data::Keywords::useRef(pEventLeagueItem->runCount),
		   Poco::Data::Keywords::now;

	result = true;

	return result;
}

STATIC bool EventLeagueItemDataModel::remove(const unsigned long eventLeagueID)
{
	Poco::Data::Session dbSession = PRPLHTTPServerApplication::instance().getDbSessionPool()->get();

	return remove(dbSession, eventLeagueID);
}

STATIC bool EventLeagueItemDataModel::remove(Poco::Data::Session& dbSession, const unsigned long eventLeagueID)
{
	bool result = true;

	Poco::Data::Statement dbStmt(dbSession);
	dbStmt << "delete from EVENT_LEAGUE_ITEM where EVENT_LEAGUE_ID = ?",
		   Poco::Data::Keywords::useRef(eventLeagueID),
		   Poco::Data::Keywords::now;

	result = true;

	return result;
}

STATIC void EventLeagueItemDataModel::free(EventLeagueItems& eventLeagueItems)
{
	std::for_each(eventLeagueItems.begin(), eventLeagueItems.end(), EventLeagueItemDataModel::freeEventLeagueItem);
	eventLeagueItems.clear();
}

STATIC void EventLeagueItemDataModel::freeEventLeagueItem(EventLeagueItem* pEventLeagueItem)
{
	if(pEventLeagueItem != NULL)
	{
		delete pEventLeagueItem;
	}
}

STATIC void EventLeagueItemDataModel::freeEventLeagueItemPair(std::pair<const unsigned long, EventLeagueItem*>& eventLeaguePair)
{
	if(eventLeaguePair.second != NULL)
	{
		delete eventLeaguePair.second;
	}
}

STATIC void EventLeagueItemDataModel::free(EventLeagueItemsMapByAthlete& eventLeaguesMapByAthlete)
{
	std::for_each(eventLeaguesMapByAthlete.begin(), eventLeaguesMapByAthlete.end(), EventLeagueItemDataModel::freeEventLeagueItemPair);
	eventLeaguesMapByAthlete.clear();
}
