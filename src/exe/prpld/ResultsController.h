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
	bool processEventLeagueForYear(const Event& event, const unsigned long year, const unsigned long latestEventResultID, EventLeagueItemsMapByAthlete& eventLeagueItemsMapByAthlete);
	unsigned long getLeagueYear(const Poco::DateTime birthday, const Poco::DateTime date);

};

#endif // ResultsController_INCLUDED
