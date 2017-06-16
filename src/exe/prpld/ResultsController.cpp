#include "ResultsController.h"

#include "PRPLHTTPServerApplication.h"
#include "EventHistoryCache.h"
#include "EventHistoryScraper.h"
#include "ResultsScraper.h"
#include "ResultsCache.h"
#include "ResultsScraper.h"

#include "dataobject/Event.h"
#include "dataobject/EventResult.h"
#include "datamodel/AthleteDataModel.h"
#include "datamodel/EventDataModel.h"
#include "datamodel/EventLeagueDataModel.h"
#include "datamodel/EventLeagueItemDataModel.h"
#include "datamodel/EventResultDataModel.h"
#include "datamodel/EventResultItemDataModel.h"

#include <Poco/Data/Transaction.h>
#include <Poco/String.h>
#include <Poco/Logger.h>
#include <Poco/Util/Application.h>
#include <Poco/DateTimeFormatter.h>
#include <Poco/Thread.h>
#include <Poco/Stopwatch.h>
#include <Poco/DateTime.h>

ResultsControllerTimer::ResultsControllerTimer() :
    _ignoreCounter(0)
{
}

void ResultsControllerTimer::onTimer(Poco::Timer& timer)
{
    // Run from ResultsHarveter Timer Thread

    // TODO : ensure this timer callback wont be fired if already in progress. Check Poco Timer functionality.
    // Otherwise if running slow, then could overload server with duplicate processing.

    // Check if we are not a popular ParkRun day (usually Saturday or national holiday). If so then slow down our harvesting by factor of X
    const unsigned long nonParkRunDaySlowDownFactor = Poco::Util::Application::instance().config().getInt("results.non-parkrun-day-slow-down-factor", 10);

    // TODO : this does not cater for public holidays and is not very international. Use xerces calendar.
    Poco::DateTime now;
    if(now.dayOfWeek() != Poco::DateTime::SATURDAY)
    {
        _ignoreCounter++;
        if(_ignoreCounter < nonParkRunDaySlowDownFactor)
        {
            poco_trace(Poco::Logger::root(), "Skipping results harvesting since this is not a usual ParkRun day.");
            return;
        }
        _ignoreCounter = 0;
    }
    else
    {
        if(now.hour() < 9 || now.hour() > 14)
        {
            _ignoreCounter++;
            if(_ignoreCounter < nonParkRunDaySlowDownFactor / 2)
            {
                poco_trace(Poco::Logger::root(), "Skipping results harvesting since outside usual ParkRun time.");
                return;
            }
            _ignoreCounter = 0;
        }
        else if(now.hour() >= 12 || now.hour() <= 14)
        {
            _ignoreCounter++;
            if(_ignoreCounter < nonParkRunDaySlowDownFactor / 4)
            {
                poco_trace(Poco::Logger::root(), "Skipping results harvesting since outside usual ParkRun time.");
                return;
            }
            _ignoreCounter = 0;
        }
    }

    const unsigned long resultsSleepBetweenEvents = Poco::Util::Application::instance().config().getInt("results.sleep-between-events-seconds", 10);

    Events events;
    EventDataModel::fetch(events);

    Events::const_iterator iterEvent;
    for(iterEvent = events.begin(); iterEvent != events.end(); ++iterEvent)
    {
        const Event* pEvent = static_cast<Event*>(*iterEvent);

        if(PRPLHTTPServerApplication::instance().isStopping())
        {
            break;
        }

        ResultsController resultsController;
        resultsController.process(pEvent->name);

        if(PRPLHTTPServerApplication::instance().isStopping())
        {
            break;
        }

        Poco::Thread::sleep(resultsSleepBetweenEvents * 1000);
    }

    EventDataModel::free(events);
}

ResultsController::ResultsController()
{
}
/*
void ResultsController::onTimer(Poco::Timer& timer)
{
    while (!PRPLHTTPServerApplication::instance().isStopping())
    {
        // Run from ResultsHarveter Thread
        const unsigned long resultsSleepBetweenEvents = Poco::Util::Application::instance().config().getInt("results.sleep-between-events-seconds", 10);

        Events events;
        EventDataModel::fetch(events);

        Events::const_iterator iterEvent;
        for(iterEvent = events.begin(); iterEvent != events.end(); ++iterEvent)
        {
            const Event* pEvent = static_cast<Event*>(*iterEvent);
            process(pEvent->name);

            Poco::Thread::sleep(resultsSleepBetweenEvents * 1000);
        }

        EventDataModel::free(events);
    }
}

VIRTUAL void ResultsController::run()
{
    // Run from ResultsHarveter Thread
    const unsigned long resultsSleepBetweenEvents = Poco::Util::Application::instance().config().getInt("results.sleep-between-events-seconds", 10);
    const unsigned long resultsSleepBetweenRuns = Poco::Util::Application::instance().config().getInt("results.sleep-between-runs-seconds", 360);

    Events events;
    EventDataModel::fetch(events);

    Events::const_iterator iterEvent;
    for(iterEvent = events.begin(); iterEvent != events.end(); ++iterEvent)
    {
        const Event* pEvent = static_cast<Event*>(*iterEvent);
        process(pEvent->name);

        Poco::Thread::sleep(resultsSleepBetweenEvents * 1000);
    }

    EventDataModel::free(events);

//        Poco::Thread::sleep(resultsSleepBetweenRuns * 1000);
}
*/
// Get the latest result
VIRTUAL bool ResultsController::process(const std::string& eventName)
{
    bool result = true;

    poco_information(Poco::Logger::root(), "Starting results harvester for " + eventName);
    Poco::Stopwatch stopWatch;
	stopWatch.start();

    // will delete any existing DB entries and recreate them - useful for Testing
    const bool recreateAllResults = Poco::Util::Application::instance().config().getBool("results.recreate-all-results", false);
    const bool useHistoryCache = Poco::Util::Application::instance().config().getBool("results.use-history-cache", false);

    std::set<unsigned long> changedLeagueYears;

    Event event;
    if(!EventDataModel::fetch(eventName, event))
    {
        return false;
    }
    else
    {
        EventHistoryScraper eventHistoryScraper;

        EventHistoryCache eventHistoryCache;
        if(useHistoryCache && eventHistoryCache.checkExists(eventName))
        {
            std::string html;
            eventHistoryCache.get(eventName, html);

            eventHistoryScraper.execute(event, html);
        }
        else
        {
            if(eventHistoryScraper.execute(event))
            {
                std::string html;
                eventHistoryScraper.getTidyHTML(html);

                if(html.empty())
                {
                    eventHistoryScraper.getHTML(html);
                }

                if(!html.empty())
                {
                    eventHistoryCache.save(eventName, html);
                }
            }
        }
        EventResults scrapedEventResults = eventHistoryScraper.getEventResults();

        // Get EventResults from database
        EventResults dbEventResults;
        EventResultDataModel::fetch(event.ID, dbEventResults);


        // Check if each EventResult is in the database, and if not then fetch it, parse it, and save it.
        EventResult* pFoundDBEventResult = NULL;

        EventResults::reverse_iterator iter;
        for(iter = scrapedEventResults.rbegin(); iter != scrapedEventResults.rend(); ++iter)
        {
            EventResult* pScrapedEventResult = *iter;
            pScrapedEventResult->eventID = event.ID;

            pFoundDBEventResult = NULL;

            // If we have found the first Result then update the Events Birthday
            if(pScrapedEventResult->resultNumber == 1 && event.birthday.isNull())
            {
                event.birthday = pScrapedEventResult->date;

                EventDataModel::update(event);
            }

            if(!event.birthday.isNull())
            {
                const unsigned long leagueYear = getLeagueYear(event.birthday.value(), pScrapedEventResult->date);

                pScrapedEventResult->leagueYear = leagueYear;
            }

            EventResults::const_iterator dbIter;
            for(dbIter = dbEventResults.begin(); dbIter != dbEventResults.end(); ++dbIter)
            {
                EventResult* pDBEventResult = *dbIter;

                if(pDBEventResult->resultNumber == pScrapedEventResult->resultNumber
                    && pDBEventResult->date == pScrapedEventResult->date)
                {
                    pFoundDBEventResult = pDBEventResult;
                    break;
                }
                if(pDBEventResult->resultNumber > pScrapedEventResult->resultNumber)
                {
                    // Since the DB records are in Ascending ResultNumber then we have passed it so get out early
                    break;
                }
            }

            // No EventResult in DB so fetch its ResultItems from website and save to db
            if(pFoundDBEventResult == NULL || recreateAllResults)
            {
                // Get EventResult from website
                EventResultItems scrapedEventResultItems;
                Athletes scrapedAthletes;
                if(processEventResult(event, *pScrapedEventResult, scrapedEventResultItems, scrapedAthletes))
                {
                    Poco::Data::Session dbSession = PRPLHTTPServerApplication::instance().getDbSessionPool()->get();
                    Poco::Data::Transaction dbTransaction(dbSession, true);
                    if(recreateAllResults)
                    {
                        EventResultDataModel::remove(dbSession, pScrapedEventResult);
                    }
                    EventResult dbEventResult;
                    if(pFoundDBEventResult == NULL || recreateAllResults)
                    {
                        EventResultDataModel::insert(dbSession, *pScrapedEventResult);

                        EventResultDataModel::fetch(dbSession, pScrapedEventResult->eventID, pScrapedEventResult->resultNumber, dbEventResult);
                        pFoundDBEventResult = &dbEventResult;

                        if(!event.birthday.isNull())
                        {
                            const unsigned long leagueYear = getLeagueYear(event.birthday.value(), dbEventResult.date);
                            changedLeagueYears.insert(leagueYear);

                            if(dbEventResult.leagueYear.isNull() || dbEventResult.leagueYear.value() != leagueYear)
                            {
                                dbEventResult.leagueYear = leagueYear;
                                EventResultDataModel::update(dbSession, dbEventResult);
                            }
                        }
                    }

                    if(recreateAllResults)
                    {
                        EventResultItemDataModel::remove(dbSession, pFoundDBEventResult->ID);
                    }
                    const unsigned long eventResultItemsCount = EventResultItemDataModel::fetchCount(dbSession, pFoundDBEventResult->ID);

                    if(eventResultItemsCount == 0)
                    {
                        EventResultItems::const_iterator iter;
                        for(iter = scrapedEventResultItems.begin(); iter != scrapedEventResultItems.end(); ++iter)
                        {
                            EventResultItem* pEventResultItem = *iter;

                            pEventResultItem->eventResultID = pFoundDBEventResult->ID;

                            EventResultItemDataModel::insert(dbSession, pEventResultItem);
                        }
                        // EventResultItemDataModel::reconcile(dbSession, pFoundDBEventResult->ID, scrapedEventResultItems);
                    }

                    AthleteDataModel::reconcile(dbSession, scrapedAthletes);

                    dbTransaction.commit();
                }

                EventResultItemDataModel::free(scrapedEventResultItems);
                AthleteDataModel::free(scrapedAthletes);
            }
        }

        EventResultDataModel::free(scrapedEventResults);
        EventResultDataModel::free(dbEventResults);
    }

    // Process event results and create leagues
    result = processEventLeagues(event, changedLeagueYears);

	poco_information(Poco::Logger::root(), "Event " + event.name + " took " + Poco::NumberFormatter::format(stopWatch.elapsedSeconds()) + " seconds.");

    return result;
}

// Get the latest result
bool ResultsController::processEventResult(const Event& event, const EventResult& eventResult, EventResultItems& eventResultItems, Athletes& athletes)
{
    bool result = false;

    ResultsScraper resultsScraper;

    ResultsCache resultsCache;
    if(resultsCache.checkExists(event.name, eventResult.resultNumber))
    {
        std::string html;
        if(resultsCache.get(event.name, eventResult.resultNumber, html))
        {
            result = resultsScraper.execute(event, eventResult, html);
        }
    }
    else
    {
        result = resultsScraper.execute(event, eventResult);
        if(result)
        {

        }
        // DEBUG TODO - Currently always save to file for checking on <xml tag issue
        std::string html;
        resultsScraper.getTidyHTML(html);

        if(html.empty())
        {
            resultsScraper.getHTML(html);
        }
        if(!html.empty())
        {
            result = resultsCache.save(event.name, eventResult.resultNumber, html);
        }
    }
    if(result)
    {
        eventResultItems = resultsScraper.getEventResultItems();
        athletes = resultsScraper.getAthletes();
    }

    return result;
}

bool ResultsController::processEventLeagues(const Event& event, const std::set<unsigned long>& changedLeagueYears)
{
    bool result = true;

    // will delete any existing DB entries and recreate them - useful for Testing
    const bool recreateAllLeagues = Poco::Util::Application::instance().config().getBool("results.recreate-all-leagues", false);

    if(event.birthday.isNull())
    {
        return false;
    }
    EventLeagues eventLeagues;
    EventLeagueItemsMapByAthlete eventLeagueItemsMapByAthlete;

    // Loop thru the EventResults in oldest first, if necessary calculate the League and update it
    EventResults dbEventResults;
    EventResultDataModel::fetch(event.ID, dbEventResults);

    bool createLeagueForYear = false;
    unsigned long lastLeagueYear = 0;
    EventResults::const_iterator iterResult;
    for(iterResult = dbEventResults.begin(); iterResult != dbEventResults.end(); ++iterResult)
    {
        const EventResult* pEventResult = static_cast<EventResult*>(*iterResult);

        // Calculate which League year from the Events birthday
        unsigned long leagueYear = 0;
        Poco::DateTime birthdayCheck;
        birthdayCheck.assign(pEventResult->date.year(), event.birthday.value().month(), event.birthday.value().day());

        if(pEventResult->date >= birthdayCheck)
        {
            leagueYear = pEventResult->date.year();
        }
        else
        {
            leagueYear = pEventResult->date.year() - 1;
        }
        createLeagueForYear = false;

        EventLeague eventLeague;
        if(!EventLeagueDataModel::fetch(event.ID, leagueYear, eventLeague))
        {
            createLeagueForYear = true;
        }
        else
        {
            // TODO : check if any new EventResults for this year and if so recreate this League
            createLeagueForYear = (changedLeagueYears.find(leagueYear) != changedLeagueYears.end());
        }

        if(!createLeagueForYear)
        {
            continue;
        }

         // Get this EventResults items and add to this League data
        EventResultItems dbEventResultItems;
        EventResultItemDataModel::fetch(pEventResult->ID, dbEventResultItems);

        EventResultItems::const_iterator iterResultItem;
        for(iterResultItem = dbEventResultItems.begin(); iterResultItem != dbEventResultItems.end(); ++iterResultItem)
        {
            const EventResultItem* pEventResultItem = static_cast<EventResultItem*>(*iterResultItem);

            if(!pEventResultItem->athleteID.isNull() && pEventResultItem->athleteID.value() > 0
               && !pEventResultItem->durationSecs.isNull() && pEventResultItem->durationSecs.value() > 0)
            {
                // TODO : the max points can vary by year, roughly depending on average number of runners of a single gender in prior year
                // I guess the actual number does not matter as long as it is big enough.
                unsigned long points = 0;
                if(!pEventResultItem->genderPosition.isNull() && pEventResultItem->genderPosition.value() < 400)
                {
                    points = 400 - pEventResultItem->genderPosition.value() + 1;
                }
                EventLeagueItemsMapByAthlete::iterator iterEventLeagueItem = eventLeagueItemsMapByAthlete.find(pEventResultItem->athleteID);
                EventLeagueItem* pEventLeagueItem = NULL;
                if(iterEventLeagueItem == eventLeagueItemsMapByAthlete.end())
                {
                    // New entry for the athlete for this years league
                    pEventLeagueItem = new EventLeagueItem(0, 0, pEventResultItem->athleteID, points, 1);
                    eventLeagueItemsMapByAthlete[pEventLeagueItem->athleteID] = pEventLeagueItem;
                }
                else
                {
                    pEventLeagueItem = static_cast<EventLeagueItem*>(iterEventLeagueItem->second);
                    pEventLeagueItem->points += points;
                    pEventLeagueItem->runCount += 1;
                }
            }
        }

        // If we have moved to a different League year the write results to database and commit
        if(lastLeagueYear != 0 && leagueYear != lastLeagueYear && !eventLeagueItemsMapByAthlete.empty())
        {
            result = processEventLeagueForYear(event, lastLeagueYear, eventLeagueItemsMapByAthlete);
        }

        lastLeagueYear = leagueYear;
    }

    // If we have moved to a different League year the write results to database and commit
    if(createLeagueForYear && !eventLeagueItemsMapByAthlete.empty())
    {
        result = processEventLeagueForYear(event, lastLeagueYear, eventLeagueItemsMapByAthlete);
    }

    return result;
}

bool ResultsController::processEventLeagueForYear(const Event& event, const unsigned long year, EventLeagueItemsMapByAthlete& eventLeagueItemsMapByAthlete)
{
    bool result = true;

    Poco::Data::Session dbSession = PRPLHTTPServerApplication::instance().getDbSessionPool()->get();
    Poco::Data::Transaction dbTransaction(dbSession, true);

    EventLeague eventLeague;
    if(EventLeagueDataModel::fetch(dbSession, event.ID, year, eventLeague))
    {
        EventLeagueDataModel::remove(dbSession, eventLeague.eventID, eventLeague.year);
        EventLeagueItemDataModel::remove(dbSession, eventLeague.ID);
    }
    else
    {
        eventLeague.eventID = event.ID;
        eventLeague.year = year;
        EventLeagueDataModel::insert(dbSession, &eventLeague);
        EventLeagueDataModel::fetch(dbSession, event.ID, year, eventLeague);
    }

    // Sort league Items by run points to get it by ascending positions
    std::multimap<const unsigned long, EventLeagueItem*> eventLeagueItemsByRunPoints;

    EventLeagueItemsMapByAthlete::const_iterator iterLeagueItems;
    for(iterLeagueItems = eventLeagueItemsMapByAthlete.begin(); iterLeagueItems != eventLeagueItemsMapByAthlete.end(); ++iterLeagueItems)
    {
        EventLeagueItem* pEventLeagueItem = static_cast<EventLeagueItem*>(iterLeagueItems->second);

        eventLeagueItemsByRunPoints.insert(std::pair<const unsigned long, EventLeagueItem*>(pEventLeagueItem->points, pEventLeagueItem));
    }

    unsigned long position = 0;
    std::multimap<const unsigned long, EventLeagueItem*>::const_reverse_iterator iterEventLeagueItemsByRunPoints;
    for(iterEventLeagueItemsByRunPoints = eventLeagueItemsByRunPoints.rbegin(); iterEventLeagueItemsByRunPoints != eventLeagueItemsByRunPoints.rend(); ++iterEventLeagueItemsByRunPoints)
    {
        EventLeagueItem* pEventLeagueItem = static_cast<EventLeagueItem*>(iterEventLeagueItemsByRunPoints->second);

        pEventLeagueItem->eventLeagueID = eventLeague.ID;
        pEventLeagueItem->position = ++position;

        poco_trace(Poco::Logger::root(),
                         "Created League result for " + event.name + " year " + Poco::NumberFormatter::format(year)
                        + " for position " + Poco::NumberFormatter::format(pEventLeagueItem->position)
                        + " for athlete " + Poco::NumberFormatter::format(pEventLeagueItem->athleteID)
                        + " with points " + Poco::NumberFormatter::format(pEventLeagueItem->points)
                        + " with runcount " + Poco::NumberFormatter::format(pEventLeagueItem->runCount));

        EventLeagueItemDataModel::insert(dbSession, pEventLeagueItem);
    }
/*
    for(iterLeagueItems = eventLeagueItemsMapByAthlete.begin(); iterLeagueItems != eventLeagueItemsMapByAthlete.end(); ++iterLeagueItems)
    {
        EventLeagueItem* pEventLeagueItem = static_cast<EventLeagueItem*>(iterLeagueItems->second);

        poco_trace(Poco::Logger::root(),
                         "Created League result for " + event.name + " year " + Poco::NumberFormatter::format(year)
                        + " for athlete " + Poco::NumberFormatter::format(pEventLeagueItem->athleteID) + " with points "
                        + Poco::NumberFormatter::format(pEventLeagueItem->points) + " with runcount " + Poco::NumberFormatter::format(pEventLeagueItem->runCount));

        pEventLeagueItem->eventLeagueID = eventLeague.ID;
        EventLeagueItemDataModel::insert(dbSession, pEventLeagueItem);
    }
*/
    dbTransaction.commit();

    poco_information(Poco::Logger::root(),
                     "Created League results for " + event.name + " and year " + Poco::NumberFormatter::format(year));

    EventLeagueItemDataModel::free(eventLeagueItemsMapByAthlete);

    return result;
}


unsigned long ResultsController::getLeagueYear(const Poco::DateTime birthday, const Poco::DateTime date)
{
    // Calculate which League year from the Events birthday
    unsigned long leagueYear = 0;
    Poco::DateTime birthdayCheck;
    birthdayCheck.assign(date.year(), birthday.month(), birthday.day());

    if(date >= birthdayCheck)
    {
        leagueYear = date.year();
    }
    else
    {
        leagueYear = date.year() - 1;
    }

    return leagueYear;
}
