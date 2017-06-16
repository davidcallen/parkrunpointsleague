#ifndef ResultsController_INCLUDED
#define ResultsController_INCLUDED

#include "dataobject/Athlete.h"
#include "dataobject/Event.h"
#include "dataobject/EventResult.h"
#include "dataobject/EventResultItem.h"
#include "dataobject/EventLeague.h"
#include "dataobject/EventLeagueItem.h"

#include <Poco/DateTime.h>
#include <Poco/Runnable.h>
#include <Poco/Timer.h>

#include <set>

#include "Common.h"

class ResultsControllerTimer
{
public:
	ResultsControllerTimer();

	void onTimer(Poco::Timer& timer);

private:
    unsigned long _ignoreCounter;
};

class ResultsController
{
public:
    ResultsController();

public:
//	void onTimer(Poco::Timer& timer);
//	virtual void run();
	virtual bool process(const std::string& eventName);

protected:
	bool processEventResult(const Event& event, const EventResult& eventResult, EventResultItems& eventResultItems, Athletes& athletes);
	bool processEventLeagues(const Event& event, const std::set<unsigned long>& changedLeagueYears);
    bool processEventLeagueForYear(const Event& event, const unsigned long year, EventLeagueItemsMapByAthlete& eventLeagueItemsMapByAthlete);
    unsigned long getLeagueYear(const Poco::DateTime birthday, const Poco::DateTime date);

};

#endif // ResultsController_INCLUDED
