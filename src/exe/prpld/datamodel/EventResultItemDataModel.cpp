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
#include "EventResultItemDataModel.h"
#include "../PRPLHTTPServerApplication.h"

#include <Poco/Util/Application.h>
#include <Poco/Data/Session.h>
#include <Poco/DateTime.h>
#include <Poco/Timespan.h>

STATIC bool EventResultItemDataModel::fetch(const unsigned long eventResultID, EventResultItems& eventResultItems)
{
    Poco::Data::Session dbSession = PRPLHTTPServerApplication::instance().getDbSessionPool()->get();

    return fetch(dbSession, eventResultID, eventResultItems);
}

STATIC bool EventResultItemDataModel::fetch(Poco::Data::Session& dbSession, const unsigned long eventResultID, EventResultItems& eventResultItems)
{
    bool result = true;

    eventResultItems.clear();

    EventResultItem tmpEventResultItem;

	Poco::Data::Statement dbStmt(dbSession);
	dbStmt << "select ID, EVENT_RESULT_ID, POSITION, GENDER_POSITION, GENDER, ATHLETE_ID, DURATION_SECS from EVENT_RESULT_ITEM where EVENT_RESULT_ID = ? order by POSITION ASC",
		   Poco::Data::Keywords::into(tmpEventResultItem.ID),
		   Poco::Data::Keywords::into(tmpEventResultItem.eventResultID),
		   Poco::Data::Keywords::into(tmpEventResultItem.position),
		   Poco::Data::Keywords::into(tmpEventResultItem.genderPosition),
		   Poco::Data::Keywords::into(tmpEventResultItem.gender),
		   Poco::Data::Keywords::into(tmpEventResultItem.athleteID),
		   Poco::Data::Keywords::into(tmpEventResultItem.durationSecs),
		   Poco::Data::Keywords::useRef(eventResultID),
		   Poco::Data::Keywords::range(0, 1);

    while (!dbStmt.done())
    {
        if(dbStmt.execute() > 0)
        {
            EventResultItem* pEventResultItem = new EventResultItem();
            *pEventResultItem = tmpEventResultItem;

            eventResultItems.push_back(pEventResultItem);
        }
    }

    return result;
}

STATIC bool EventResultItemDataModel::fetch(const unsigned long eventResultID, const unsigned long athleteID, EventResultItem& eventResultItem)
{
    Poco::Data::Session dbSession = PRPLHTTPServerApplication::instance().getDbSessionPool()->get();

    return fetch(dbSession, eventResultID, athleteID, eventResultItem);
}

STATIC bool EventResultItemDataModel::fetch(Poco::Data::Session& dbSession, const unsigned long eventResultID,
                                            const unsigned long athleteID, EventResultItem& eventResultItem)
{
    bool result = true;

	Poco::Data::Statement dbStmt(dbSession);
	dbStmt << "select ID, EVENT_RESULT_ID, POSITION, GENDER_POSITION, GENDER, ATHLETE_ID, DURATION_SECS from EVENT_RESULT_ITEM where EVENT_RESULT_ID = ? and ATHLETE_ID = ? order by POSITION ASC",
		   Poco::Data::Keywords::into(eventResultItem.ID),
		   Poco::Data::Keywords::into(eventResultItem.eventResultID),
		   Poco::Data::Keywords::into(eventResultItem.position),
		   Poco::Data::Keywords::into(eventResultItem.genderPosition),
		   Poco::Data::Keywords::into(eventResultItem.gender),
		   Poco::Data::Keywords::into(eventResultItem.athleteID),
		   Poco::Data::Keywords::into(eventResultItem.durationSecs),
		   Poco::Data::Keywords::useRef(eventResultID),
		   Poco::Data::Keywords::useRef(athleteID),
		   Poco::Data::Keywords::now;

    result = (eventResultItem.ID != 0);

    return result;
}

STATIC unsigned long EventResultItemDataModel::fetchCount(const unsigned long eventResultID)
{
    Poco::Data::Session dbSession = PRPLHTTPServerApplication::instance().getDbSessionPool()->get();

    return fetchCount(dbSession, eventResultID);
}

STATIC unsigned long EventResultItemDataModel::fetchCount(Poco::Data::Session& dbSession, const unsigned long eventResultID)
{
    unsigned long count = 0;

	Poco::Data::Statement dbStmt(dbSession);
	dbStmt << "select count(*) as COUNT from EVENT_RESULT_ITEM where EVENT_RESULT_ID = ?",
		   Poco::Data::Keywords::into(count),
		   Poco::Data::Keywords::useRef(eventResultID),
		   Poco::Data::Keywords::now;

    return count;
}

STATIC bool EventResultItemDataModel::insert(EventResultItem* pEventResultItem)
{
    Poco::Data::Session dbSession = PRPLHTTPServerApplication::instance().getDbSessionPool()->get();

    return insert(dbSession, pEventResultItem);
}

STATIC bool EventResultItemDataModel::insert(Poco::Data::Session& dbSession, EventResultItem* pEventResultItem)
{
    bool result = true;

	Poco::Data::Statement dbStmt(dbSession);
	dbStmt << "insert into EVENT_RESULT_ITEM (EVENT_RESULT_ID, POSITION, GENDER_POSITION, GENDER, ATHLETE_ID, DURATION_SECS) values (?, ?, ?, ?, ?, ?)",
		   Poco::Data::Keywords::useRef(pEventResultItem->eventResultID),
		   Poco::Data::Keywords::useRef(pEventResultItem->position),
		   Poco::Data::Keywords::useRef(pEventResultItem->genderPosition),
		   Poco::Data::Keywords::useRef(pEventResultItem->gender),
		   Poco::Data::Keywords::useRef(pEventResultItem->athleteID),
		   Poco::Data::Keywords::useRef(pEventResultItem->durationSecs),
		   Poco::Data::Keywords::now;

    result = true;

    return result;
}

/*
STATIC bool EventResultItemDataModel::reconcile(const EventResultItems& athletes)
{
    Poco::Data::Session dbSession = PRPLHTTPServerApplication::instance().getDbSessionPool()->get();

    return reconcile(dbSession, athletes);
}

STATIC bool EventResultItemDataModel::reconcile(Poco::Data::Session& dbSession, const EventResultItems& eventResultItems)
{
    bool result = false;

    if(eventResultItems.empty())
    {
        return true;
    }

    // Get all the EventResultItems from Database
    EventResultItemsMap existingDBeventResultItemsMap;
    EventResultItemDataModel::fetch(dbSession, existingDBeventResultItemsMap);

    EventResultItems::const_iterator iter;
    for(iter = eventResultItems.begin(); iter != eventResultItems.end(); ++iter)
    {
        EventResultItem* pEventResultItem = *iter;

        EventResultItemsMap::iterator existingDBeventResultItemIter = existingDBeventResultItemsMap.find(pEventResultItem->ID);
        if(existingDBeventResultItemIter == existingDBeventResultItemsMap.end())
        {
            result = EventResultItemDataModel::insert(dbSession, *pEventResultItem);
        }
        else
        {
            result = EventResultItemDataModel::update(dbSession, *pEventResultItem);
        }
        if(!result)
        {
            break;
        }
        // We dont remove any EventResultItems
    }

    EventResultItemDataModel::free(existingDBeventResultItemsMap);

    return result;
}
*/
STATIC bool EventResultItemDataModel::remove(const unsigned long eventResultID)
{
    Poco::Data::Session dbSession = PRPLHTTPServerApplication::instance().getDbSessionPool()->get();

    return remove(dbSession, eventResultID);
}

STATIC bool EventResultItemDataModel::remove(Poco::Data::Session& dbSession, const unsigned long eventResultID)
{
    bool result = true;

	Poco::Data::Statement dbStmt(dbSession);
	dbStmt << "delete from EVENT_RESULT_ITEM where EVENT_RESULT_ID = ?",
		   Poco::Data::Keywords::useRef(eventResultID),
		   Poco::Data::Keywords::now;

    result = true;

    return result;
}

STATIC void EventResultItemDataModel::free(EventResultItems& eventResultItems)
{
    std::for_each(eventResultItems.begin(), eventResultItems.end(), EventResultItemDataModel::freeEventResultItem);
    eventResultItems.clear();
}

STATIC void EventResultItemDataModel::freeEventResultItem(EventResultItem* pEventResultItem)
{
    if(pEventResultItem != NULL)
    {
        delete pEventResultItem;
    }
}
