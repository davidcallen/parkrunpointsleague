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
#include "GetLatestResultHandler.h"
#include "../ResultsController.h"

#include "../dataobject/Event.h"
#include "../datamodel/EventDataModel.h"
#include "../dataobject/EventResult.h"
#include "../datamodel/EventResultDataModel.h"
#include "../datamodel/EventResultItemDataModel.h"

#include <Poco/DateTime.h>
#include <Poco/DateTimeFormatter.h>
#include <Poco/DateTimeFormat.h>
#include <Poco/NumberFormatter.h>
#include <Poco/Timespan.h>

#include <Poco/Logger.h>

#include <Poco/ThreadLocal.h>

#include <Poco/Util/Application.h>

void GetLatestResultHandler::handleRequest(Poco::Net::HTTPServerRequest& request, Poco::Net::HTTPServerResponse& response)
{
	try
	{
		response.setChunkedTransferEncoding(true);
		response.setContentType("text/html");
		response.set("cache-control", "max-age=0");

		Poco::DateTime now;
		std::string timeString(Poco::DateTimeFormatter::format(now, Poco::DateTimeFormat::SORTABLE_FORMAT));

		Event event;
		if(!EventDataModel::fetch("miltonkeynes", event))
		{
			std::ostream& responseStream = response.send();
			responseStream << "<html><head><head><title>ParkRun Points League</title></head>";
			responseStream << "<body><h1>Error</h1>";
			responseStream << "<p>Sorry, this ParkRun is not currently in our database.</p>";
			responseStream << "</body></html>";
		}
		else
		{
			Poco::DateTime latestResultDate;
			EventResultDataModel::getLastResultDate(latestResultDate);

			EventResults eventResults;
			if(EventResultDataModel::fetch(event.ID, latestResultDate, eventResults))
			{
				std::ostream& responseStream = response.send();
				responseStream << "<html><head><head><title>ParkRun Points League</title></head>";
				responseStream << "<body><h1>Event #" + Poco::NumberFormatter::format(event.ID) + + " on "
					+ Poco::DateTimeFormatter::format(latestResultDate, Poco::DateTimeFormat::SORTABLE_FORMAT) + "</h1>";
				responseStream << "<table>";
				responseStream << "</table>";
				responseStream << "</body></html>";
			}
			else
			{
				std::ostream& responseStream = response.send();
				responseStream << "<html><head><head><title>ParkRun Points League</title></head>";
				responseStream << "<body><h1>Error</h1>";
				responseStream << "<p>Sorry, the latest ParkRun Result is not currently in our database.</p>";
				responseStream << "</body></html>";
			}
		}
/*
		Event event;
		if(!EventDataModel::fetch("miltonkeynes", event))
		{
			std::ostream& responseStream = response.send();
			responseStream << "<html><head><head><title>ParkRun Points League</title></head>";
			responseStream << "<body><h1>Error</h1>";
			responseStream << "<p>Sorry, this ParkRun is not currently in our database.</p>";
			responseStream << "</body></html>";
		}
		else
		{
			Poco::DateTime latestResultDate;
			EventResultDataModel::getLastResultDate(latestResultDate);

			EventResult eventResult;
			if(EventResultDataModel::fetch(event.ID, latestResultDate, eventResult))
			{
				// Already have the result
			}
			else
			{
				ResultsCache resultsCache;
				resultsCache.

				ResultsScraper resultsScraper;

				resultsScraper.execute(event.name);
				EventResult& eventResult = resultsScraper.getEventResult();
				eventResult.eventID = event.ID;
				if(eventResult.resultNumber != 0)
				{
					EventResultDataModel::insert(eventResult);

					EventResultItems& eventResultItems = resultsScraper.getEventResultItems();
					EventResultItems::const_iterator iter;
					for(iter = eventResultItems.begin(); iter != eventResultItems.end(); ++iter)
					{
						EventResultItemDataModel::insert(*iter);
					}
				}
			}
		}
*/
	}
	catch (Poco::Exception& e)
	{
		poco_error_f2(Poco::Logger::root(), "HTTP request %s had error %s", request.getURI(), e.displayText());
		responseProblem(request, response, "Get latest results", "Something bad happened");
	}
}
