#include "EventResultDataModel.h"
#include "../PRPLHTTPServerApplication.h"

#include <Poco/Util/Application.h>
#include <Poco/Data/Session.h>
#include <Poco/DateTime.h>
#include <Poco/Timespan.h>


STATIC void EventResultDataModel::getLastResultDate(Poco::DateTime& date)
{
    Poco::DateTime now;

    date.assign(now.year(), now.month(), now.day(), 0, 0, 0, 0, 0);

    if(date.dayOfWeek() != Poco::DateTime::SATURDAY)
    {
        Poco::Timespan adjustDays(date.dayOfWeek() + 1, 0, 0, 0, 0);
        date -= adjustDays;
    }
}

STATIC bool EventResultDataModel::fetch(const unsigned long eventID, const Poco::DateTime& date, EventResults& eventResults)
{
    Poco::Data::Session dbSession = PRPLHTTPServerApplication::instance().getDbSessionPool()->get();

    return fetch(dbSession, eventID, date, eventResults);
}

STATIC bool EventResultDataModel::fetch(Poco::Data::Session& dbSession, const unsigned long eventID, const Poco::DateTime& date, EventResults& eventResults)
{
    bool result = true;

    EventResult tmpEventResult;

	Poco::Data::Statement dbStmt(dbSession);
	dbStmt << "select ID, EVENT_ID, RESULT_NUMBER, DATE, LEAGUE_YEAR from EVENT_RESULT where EVENT_ID = ? and DATE = ? order by RESULT_NUMBER DESC",
		   Poco::Data::Keywords::into(tmpEventResult.ID),
		   Poco::Data::Keywords::into(tmpEventResult.eventID),
		   Poco::Data::Keywords::into(tmpEventResult.resultNumber),
		   Poco::Data::Keywords::into(tmpEventResult.date),
		   Poco::Data::Keywords::into(tmpEventResult.leagueYear),
		   Poco::Data::Keywords::useRef(eventID),
		   Poco::Data::Keywords::useRef(date),
		   Poco::Data::Keywords::range(0, 1);

	while (!dbStmt.done())
	{
        if(dbStmt.execute() > 0)
        {
            EventResult* pEventResult = new EventResult;
            *pEventResult = tmpEventResult;

            eventResults.push_back(pEventResult);
        }
	}

    return result;
}


STATIC bool EventResultDataModel::fetch(const unsigned long eventID, const unsigned long leagueYear, EventResults& eventResults)
{
    Poco::Data::Session dbSession = PRPLHTTPServerApplication::instance().getDbSessionPool()->get();

    return fetch(dbSession, eventID, leagueYear, eventResults);
}

STATIC bool EventResultDataModel::fetch(Poco::Data::Session& dbSession, const unsigned long eventID, const unsigned long leagueYear, EventResults& eventResults)
{
    bool result = true;

    EventResult tmpEventResult;

	Poco::Data::Statement dbStmt(dbSession);
	dbStmt << "select ID, EVENT_ID, RESULT_NUMBER, DATE, LEAGUE_YEAR from EVENT_RESULT where EVENT_ID = ? and LEAGUE_YEAR = ? order by RESULT_NUMBER DESC",
		   Poco::Data::Keywords::into(tmpEventResult.ID),
		   Poco::Data::Keywords::into(tmpEventResult.eventID),
		   Poco::Data::Keywords::into(tmpEventResult.resultNumber),
		   Poco::Data::Keywords::into(tmpEventResult.date),
		   Poco::Data::Keywords::into(tmpEventResult.leagueYear),
		   Poco::Data::Keywords::useRef(eventID),
		   Poco::Data::Keywords::useRef(leagueYear),
		   Poco::Data::Keywords::range(0, 1);

	while (!dbStmt.done())
	{
        if(dbStmt.execute() > 0)
        {
            EventResult* pEventResult = new EventResult;
            *pEventResult = tmpEventResult;

            eventResults.push_back(pEventResult);
        }
	}

    return result;
}

STATIC bool EventResultDataModel::fetch(const unsigned long eventID, EventResults& eventResults)
{
    Poco::Data::Session dbSession = PRPLHTTPServerApplication::instance().getDbSessionPool()->get();

    return fetch(dbSession, eventID, eventResults);
}

STATIC bool EventResultDataModel::fetch(Poco::Data::Session& dbSession, const unsigned long eventID, EventResults& eventResults)
{
    bool result = true;

    EventResult tmpEventResult;

	Poco::Data::Statement dbStmt(dbSession);
	dbStmt << "select ID, EVENT_ID, RESULT_NUMBER, DATE, LEAGUE_YEAR from EVENT_RESULT where EVENT_ID = ? order by RESULT_NUMBER ASC",
		   Poco::Data::Keywords::into(tmpEventResult.ID),
		   Poco::Data::Keywords::into(tmpEventResult.eventID),
		   Poco::Data::Keywords::into(tmpEventResult.resultNumber),
		   Poco::Data::Keywords::into(tmpEventResult.date),
		   Poco::Data::Keywords::into(tmpEventResult.leagueYear),
		   Poco::Data::Keywords::useRef(eventID),
		   Poco::Data::Keywords::range(0, 1);

	while (!dbStmt.done())
	{
        if(dbStmt.execute() > 0)
        {
            EventResult* pEventResult = new EventResult;
            *pEventResult = tmpEventResult;

            eventResults.push_back(pEventResult);
        }
	}

    return result;
}

STATIC bool EventResultDataModel::fetch(const unsigned long eventResultID, EventResult& eventResult)
{
    Poco::Data::Session dbSession = PRPLHTTPServerApplication::instance().getDbSessionPool()->get();

    return fetch(dbSession, eventResultID, eventResult);
}

STATIC bool EventResultDataModel::fetch(Poco::Data::Session& dbSession, const unsigned long eventResultID, EventResult& eventResult)
{
    bool result = true;

    eventResult.ID = 0;

	Poco::Data::Statement dbStmt(dbSession);
	dbStmt << "select ID, EVENT_ID, RESULT_NUMBER, DATE, LEAGUE_YEAR from EVENT_RESULT where ID = ?",
		   Poco::Data::Keywords::into(eventResult.ID),
		   Poco::Data::Keywords::into(eventResult.eventID),
		   Poco::Data::Keywords::into(eventResult.resultNumber),
		   Poco::Data::Keywords::into(eventResult.date),
		   Poco::Data::Keywords::into(eventResult.leagueYear),
		   Poco::Data::Keywords::useRef(eventResultID),
		   Poco::Data::Keywords::now;

    result = (eventResult.ID != 0);

    return result;
}

STATIC bool EventResultDataModel::fetch(const unsigned long eventID, const unsigned long resultNumber, EventResult& eventResult)
{
    Poco::Data::Session dbSession = PRPLHTTPServerApplication::instance().getDbSessionPool()->get();

    return fetch(dbSession, eventID, resultNumber, eventResult);
}

STATIC bool EventResultDataModel::fetch(Poco::Data::Session& dbSession, const unsigned long eventID, const unsigned long resultNumber, EventResult& eventResult)
{
    bool result = true;

    eventResult.ID = 0;

	Poco::Data::Statement dbStmt(dbSession);
	dbStmt << "select ID, EVENT_ID, RESULT_NUMBER, DATE, LEAGUE_YEAR from EVENT_RESULT where EVENT_ID = ? and RESULT_NUMBER = ?",
		   Poco::Data::Keywords::into(eventResult.ID),
		   Poco::Data::Keywords::into(eventResult.eventID),
		   Poco::Data::Keywords::into(eventResult.resultNumber),
		   Poco::Data::Keywords::into(eventResult.date),
		   Poco::Data::Keywords::into(eventResult.leagueYear),
		   Poco::Data::Keywords::useRef(eventID),
		   Poco::Data::Keywords::useRef(resultNumber),
		   Poco::Data::Keywords::now;

    result = (eventResult.ID != 0);

    return result;
}

STATIC bool EventResultDataModel::update(const EventResult& eventResult)
{
    Poco::Data::Session dbSession = PRPLHTTPServerApplication::instance().getDbSessionPool()->get();

    return update(dbSession, eventResult);
}

STATIC bool EventResultDataModel::update(Poco::Data::Session& dbSession, const EventResult& eventResult)
{
    bool result = true;

	Poco::Data::Statement dbStmt(dbSession);
	dbStmt << "update EVENT_RESULT set EVENT_ID = ?, RESULT_NUMBER = ?, DATE = ?, LEAGUE_YEAR = ? where ID = ?",
		   Poco::Data::Keywords::useRef(eventResult.eventID),
		   Poco::Data::Keywords::useRef(eventResult.resultNumber),
		   Poco::Data::Keywords::useRef(eventResult.date),
		   Poco::Data::Keywords::useRef(eventResult.leagueYear.value()),
		   Poco::Data::Keywords::useRef(eventResult.ID),
		   Poco::Data::Keywords::now;

    result = true;

    return result;
}

STATIC bool EventResultDataModel::insert(const EventResult& eventResult)
{
    Poco::Data::Session dbSession = PRPLHTTPServerApplication::instance().getDbSessionPool()->get();

    return insert(dbSession, eventResult);
}

STATIC bool EventResultDataModel::insert(Poco::Data::Session& dbSession, const EventResult& eventResult)
{
    bool result = true;

	Poco::Data::Statement dbStmt(dbSession);
	dbStmt << "insert into EVENT_RESULT (EVENT_ID, RESULT_NUMBER, DATE, LEAGUE_YEAR) values (?, ?, ?, ?)",
		   Poco::Data::Keywords::useRef(eventResult.eventID),
		   Poco::Data::Keywords::useRef(eventResult.resultNumber),
		   Poco::Data::Keywords::useRef(eventResult.date),
		   Poco::Data::Keywords::useRef(eventResult.leagueYear.value()),
		   Poco::Data::Keywords::now;

    result = true;

    return result;
}

STATIC bool EventResultDataModel::remove(const EventResult* pEventResult)
{
    Poco::Data::Session dbSession = PRPLHTTPServerApplication::instance().getDbSessionPool()->get();

    return remove(dbSession, pEventResult);
}

STATIC bool EventResultDataModel::remove(Poco::Data::Session& dbSession, const EventResult* pEventResult)
{
    return remove(dbSession, pEventResult->resultNumber);
}

STATIC bool EventResultDataModel::remove(const unsigned long eventResultNumber)
{
    Poco::Data::Session dbSession = PRPLHTTPServerApplication::instance().getDbSessionPool()->get();

    return remove(dbSession, eventResultNumber);
}

STATIC bool EventResultDataModel::remove(Poco::Data::Session& dbSession, const unsigned long eventResultNumber)
{
    bool result = true;

	Poco::Data::Statement dbStmt(dbSession);
	dbStmt << "delete from EVENT_RESULT where RESULT_NUMBER = ?",
		   Poco::Data::Keywords::useRef(eventResultNumber),
		   Poco::Data::Keywords::now;

    result = true;

    return result;
}


STATIC void EventResultDataModel::free(EventResults& eventResults)
{
    std::for_each(eventResults.begin(), eventResults.end(), EventResultDataModel::freeEventResult);
    eventResults.clear();
}

STATIC void EventResultDataModel::freeEventResult(EventResult* pEventResult)
{
    if(pEventResult != NULL)
    {
        delete pEventResult;
    }
}
