#include "EventLeagueHandler.h"
#include "../ResultsController.h"

#include "../datamodel/EventDataModel.h"
#include "../datamodel/EventLeagueDataModel.h"
#include "../datamodel/EventLeagueItemDataModel.h"
#include "../datamodel/AthleteDataModel.h"

#include <Poco/DateTime.h>
#include <Poco/DateTimeFormatter.h>
#include <Poco/DateTimeFormat.h>
#include <Poco/NumberFormatter.h>
#include <Poco/Timespan.h>

#include <Poco/Logger.h>
#include <Poco/URI.h>

#include <Poco/ThreadLocal.h>

#include <Poco/Util/Application.h>

void EventLeagueHandler::handleRequest(Poco::Net::HTTPServerRequest& request, Poco::Net::HTTPServerResponse& response)
{
	try
	{
        const std::string& requestURI = request.getURI();

        std::vector<std::string> uriSegments;
        Poco::URI uri(requestURI);
        uri.getPathSegments(uriSegments);

		response.setChunkedTransferEncoding(true);
		response.setContentType("text/html");

        // Get query arguments
        unsigned long year = 0;
        std::string eventName = "miltonkeynes";
        if(uriSegments.size() > 1)
        {
            eventName = uriSegments[1];
        }
        if(uriSegments.size() > 2)
        {
            year = Poco::NumberParser::parseUnsigned(uriSegments[2]);
        }

		Event event;
		if(!EventDataModel::fetch(eventName, event))
		{
		    responseProblem(request, response, "Event League", "Sorry, this ParkRun is not currently in our database.");
		}
		else
		{
		    // Fetch EventLeagues in Year Desc order
            EventLeagues eventLeagues;
            EventLeagueDataModel::fetch(event.ID, eventLeagues);

			EventLeague* pEventLeagueFound = NULL;
            EventLeagues::const_iterator iterLeague;
            for(iterLeague = eventLeagues.begin(); iterLeague != eventLeagues.end(); ++iterLeague)
            {
                EventLeague* pEventLeague = static_cast<EventLeague*>(*iterLeague);
                if(year == 0 || pEventLeague->year == year)
                {
                    year = pEventLeague->year;
                    pEventLeagueFound = pEventLeague;
                    break;
                }
            }

			EventLeagueItems eventLeagueItems;
			if(pEventLeagueFound != NULL)
            {
                EventLeagueItemDataModel::fetch(pEventLeagueFound->ID, eventLeagueItems);
            }

            if(event.birthday.isNull())
            {
                responseProblem(request, response, event.title + " League", "Sorry, this ParkRun is not currently in our database.");
            }

            std::ostream& responseStream = response.send();
            std::string additionalHeader;
/*            additionalHeader += "  <script>\n";
            additionalHeader += "    $(document).ready(function(){ \n";
            additionalHeader += "      $(\"#events\").selectmenu({\n";
            additionalHeader += "        select: function( event, data ) {\n";
            additionalHeader += "          window.location.href = \"/league/\" + data.item.value + \"/" + Poco::NumberFormatter::format(year) + "\";\n";
            additionalHeader += "        }\n";
            additionalHeader += "      });\n";
            additionalHeader += "      $(\"#eventYear\").selectmenu({\n";
            additionalHeader += "        select: function( event, data ) {\n";
            additionalHeader += "          window.location.href = \"/league/" + eventName + "/\" + data.item.value;\n";
            additionalHeader += "        }\n";
            additionalHeader += "      });\n";
            additionalHeader += "    });\n";
            additionalHeader += "  </script>\n";*/
            std::string pageTitle = event.title + " League for " + Poco::NumberFormatter::format(year);

            responseStream << getHeader(pageTitle, true, additionalHeader);

            responseStream << "<div class=\"events\" ><select name=\"events\" id=\"events\" >\n";
            Events events;
            EventDataModel::fetch(events);
            Events::const_iterator iterEvent;
            for(iterEvent = events.begin(); iterEvent != events.end(); ++iterEvent)
            {
                const Event* pEvent = static_cast<Event*>(*iterEvent);

                std::string selected;
                if(eventName == pEvent->name)
                {
                    selected = "selected=\"selected\"";
                }
                responseStream << "<option " << selected << " value=\""<< pEvent->name << "\">"<< pEvent->name << "</option>\n";
            }
            responseStream << "</select></div>\n";

            // JavaScript for dropdown years list
            responseStream << "<div class=\"event-years\"><select name=\"eventYear\" id=\"eventYear\" >\n";

            for(iterLeague = eventLeagues.begin(); iterLeague != eventLeagues.end(); ++iterLeague)
            {
                EventLeague* pEventLeague = static_cast<EventLeague*>(*iterLeague);

                std::string yearOptionStr = Poco::NumberFormatter::format(pEventLeague->year);
                std::string selected;
                if(year == pEventLeague->year)
                {
                    selected = "selected=\"selected\"";
                }
                responseStream << "<option " << selected << " value=\""<< yearOptionStr << "\">"<< yearOptionStr << "</option>\n";
            }
            responseStream << "</select></div>\n";

            // Prevent delayed render of "select" jquery menu by putting script in body here (rather than in header)
            responseStream << "  <script>\n";
            responseStream << "      $(\"#events\").selectmenu({\n";
            responseStream << "        select: function( event, data ) {\n";
            responseStream << "          window.location.href = \"/league/\" + data.item.value + \"/" + Poco::NumberFormatter::format(year) + "\";\n";
            responseStream << "        }\n";
            responseStream << "      });\n";
            responseStream << "      $(\"#eventYear\").selectmenu({\n";
            responseStream << "        select: function( event, data ) {\n";
            responseStream << "          window.location.href = \"/league/" + eventName + "/\" + data.item.value;\n";
            responseStream << "        }\n";
            responseStream << "      });\n";
            responseStream << "  </script>\n";

            responseStream << "<table>\n";
            responseStream << "<tr>\n";
            responseStream << "<th>Position</th>";
            responseStream << "<th>Athlete</th>";
            responseStream << "<th>Points</th>";
            responseStream << "<th>Runs</th>";
            responseStream << "</tr>\n";

            AthletesMap athletesMap;
            if(!eventLeagueItems.empty())
            {
                // TODO : this could become problematic to scale when many events and many athletes !!
                // Use and athletes cache
                AthleteDataModel::fetch(athletesMap);
            }

            EventLeagueItems::const_iterator iterLeagueItem;
            for(iterLeagueItem = eventLeagueItems.begin(); iterLeagueItem != eventLeagueItems.end(); ++iterLeagueItem)
            {
                EventLeagueItem* pEventLeagueItem = static_cast<EventLeagueItem*>(*iterLeagueItem);

                std::string athleteName;
                AthletesMap::const_iterator iterAthlete = athletesMap.find(pEventLeagueItem->athleteID);
                if(iterAthlete != athletesMap.end())
                {
                    Athlete* pAthelete = static_cast<Athlete*>(iterAthlete->second);
                    athleteName = pAthelete->first_name + " " + pAthelete->last_name;
                }

                responseStream << "<tr>\n";
                responseStream << "<td>" + Poco::NumberFormatter::format(pEventLeagueItem->position) + "</td>";
                responseStream << "<td><a href=\"/athlete/" +event.name + "/" + Poco::NumberFormatter::format(pEventLeagueItem->athleteID)
                                    + "?year=" + Poco::NumberFormatter::format(year) + "\">" + athleteName + "</a></td>";
                responseStream << "<td>" + Poco::NumberFormatter::format(pEventLeagueItem->points) + "</td>";
                responseStream << "<td>" + Poco::NumberFormatter::format(pEventLeagueItem->runCount) + "</td>";
                responseStream << "</tr>\n";
            }
            responseStream << "</table>\n";
            responseStream << "<p>This league started on " << Poco::DateTimeFormatter::format(event.birthday.value(), "%b-%d") << "</p>";
            responseStream << "</body></html>\n";

            EventLeagueDataModel::free(eventLeagues);
            EventLeagueItemDataModel::free(eventLeagueItems);
            AthleteDataModel::free(athletesMap);
		}
	}
	catch (Poco::Exception& e)
	{
//		std::cerr << e.displayText() << std::endl;
		poco_error_f2(Poco::Logger::root(), "HTTP request %s had error %s", request.getURI(), e.displayText());
	}
}

