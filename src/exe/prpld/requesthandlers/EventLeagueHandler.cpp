#include "EventLeagueHandler.h"
#include "../ResultsController.h"

#include "../datamodel/EventDataModel.h"
#include "../datamodel/EventLeagueDataModel.h"
#include "../datamodel/EventLeagueItemDataModel.h"
#include "../datamodel/EventResultDataModel.h"
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
        Poco::URI uri(requestURI);

		response.setChunkedTransferEncoding(true);
		response.setContentType("text/html");
		response.set("cache-control", "max-age=0");

        // Get query arguments
        std::string requestFilterByEventName;
        unsigned long requestFilterByYear = 0;
        std::string requestFilterByGender;

        Poco::URI::QueryParameters queryParameters = uri.getQueryParameters();
        Poco::URI::QueryParameters::const_iterator iterQueryParams;
        for(iterQueryParams = queryParameters.begin(); iterQueryParams != queryParameters.end(); ++iterQueryParams)
        {
			if(iterQueryParams->first == "e")
			{
				requestFilterByEventName = iterQueryParams->second;
			}
			else if(iterQueryParams->first == "g")
			{
				requestFilterByGender = iterQueryParams->second;
			}
			else if(iterQueryParams->first == "y")
			{
				unsigned int yearTemp = 0;
				if(Poco::NumberParser::tryParseUnsigned(iterQueryParams->second, yearTemp))
				{
					requestFilterByYear = yearTemp;
				}
			}
		}

		Event event;
		if(!EventDataModel::fetch(requestFilterByEventName, event))
		{
		    responseProblem(request, response, "Event League", "Sorry, this ParkRun is not currently in our database.");
		    return;
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
                if(requestFilterByYear == 0 || pEventLeague->year == requestFilterByYear)
                {
                    requestFilterByYear = pEventLeague->year;
                    pEventLeagueFound = pEventLeague;
                    break;
                }
            }

            if(requestFilterByYear == 0)
            {
                responseProblem(request, response, event.title + " League", "Sorry, this ParkRun is not currently in our database.");

                return;
            }

			EventLeagueItems eventLeagueItems;
			if(pEventLeagueFound != NULL)
            {
                std::string orderByFieldName = "POSITION";
                if(!requestFilterByGender.empty())
                {
                    orderByFieldName = "GENDER_POSITION";
                }
                EventLeagueItemDataModel::fetch(pEventLeagueFound->ID, orderByFieldName, eventLeagueItems);
            }

            if(event.birthday.isNull())
            {
                responseProblem(request, response, event.title + " League", "Sorry, this ParkRun is not currently in our database.");

                return;
            }

            std::ostream& responseStream = response.send();

            std::string additionalHeader;
            std::string pageTitle = event.title + " League for " + Poco::NumberFormatter::format(requestFilterByYear);
            responseStream << getHeader(pageTitle, true, additionalHeader);

            responseStream << "<div class=\"league-selectors\" >\n";
            responseStream << "<div class=\"events\" ><select name=\"eventName\" id=\"eventName\" >\n";
            Events events;
            EventDataModel::fetch(events);
            Events::const_iterator iterEvent;
            for(iterEvent = events.begin(); iterEvent != events.end(); ++iterEvent)
            {
                const Event* pEvent = static_cast<Event*>(*iterEvent);

                std::string selected;
                if(requestFilterByEventName == pEvent->name)
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
                if(requestFilterByYear == pEventLeague->year)
                {
                    selected = "selected=\"selected\"";
                }
                responseStream << "<option " << selected << " value=\""<< yearOptionStr << "\">"<< yearOptionStr << "</option>\n";
            }
            responseStream << "</select></div>\n";

            // JavaScript for dropdown gender selection
            std::string genderSelected;
            responseStream << "<div class=\"gender\"><select name=\"gender\" id=\"gender\" >\n";
            if(requestFilterByGender.empty())
            {
                genderSelected = "selected=\"selected\"";
            }
            responseStream << "<option " << genderSelected << " value=\"\">Combined</option>\n";
            genderSelected = "";
            if(requestFilterByGender == Athlete::GENDER_CHAR_MALE)
            {
                genderSelected = "selected=\"selected\"";
            }
            responseStream << "<option " << genderSelected << " value=\"" << Athlete::GENDER_CHAR_MALE << "\">" << Athlete::GENDER_CHAR_MALE << "</option>\n";
            genderSelected = "";
            if(requestFilterByGender == Athlete::GENDER_CHAR_FEMALE)
            {
                genderSelected = "selected=\"selected\"";
            }
            responseStream << "<option " << genderSelected << " value=\"" << Athlete::GENDER_CHAR_FEMALE << "\">" << Athlete::GENDER_CHAR_FEMALE << "</option>\n";
            responseStream << "</select></div>\n";
            responseStream << "<button onClick=\"bntClickGO(this.form)\">GO</button>\n";
            responseStream << "</div>\n"; // for <div class=league-selectors >

            if(pEventLeagueFound == NULL)
            {
                responseStream << "<p>This league started on " << Poco::DateTimeFormatter::format(event.birthday.value(), "%d %b %Y") << "</p>";
            }
            else
            {
                Poco::DateTime leagueStartDate;
                leagueStartDate.assign(pEventLeagueFound->year, event.birthday.value().month(), event.birthday.value().day());
                responseStream << "<p>This league started on " << Poco::DateTimeFormatter::format(leagueStartDate, "%d %b %Y") << "</p>";

                EventResult latestEventResult;
                if(EventResultDataModel::fetch(pEventLeagueFound->latestEventResultID, latestEventResult))
                {
                    responseStream << "<p>This latest result for this league is #" << Poco::NumberFormatter::format(latestEventResult.resultNumber)
                                    << " on " << Poco::DateTimeFormatter::format(latestEventResult.date, "%d %b %Y") << "</p>";
                }
            }

            // Prevent delayed render of "select" jquery menu by putting script in body here (rather than in header)
            responseStream << "  <script>\n";
            responseStream << "      $(\"#eventName\").selectmenu({\n";
            responseStream << "      });\n";
            responseStream << "      $(\"#eventYear\").selectmenu({\n";
            responseStream << "      });\n";
            responseStream << "      $(\"#gender\").selectmenu({\n";
            responseStream << "      });\n";
            responseStream << "      function bntClickGO(form) {\n";
            responseStream << "        var eventName = $(\"#eventName\").val();\n";
            responseStream << "        var year = $(\"#eventYear\").val();\n";
            responseStream << "        var gender = $(\"#gender\").val();\n";
            responseStream << "        window.location.href = \"/league?e=\" + eventName + \"&y=\" + year + \"&g=\" + gender;\n";
            responseStream << "      }\n";
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
                // Use an athletes cache
                AthleteDataModel::fetch(athletesMap);
            }

            EventLeagueItems::const_iterator iterLeagueItem;
            for(iterLeagueItem = eventLeagueItems.begin(); iterLeagueItem != eventLeagueItems.end(); ++iterLeagueItem)
            {
                EventLeagueItem* pEventLeagueItem = static_cast<EventLeagueItem*>(*iterLeagueItem);

                if(!requestFilterByGender.empty())
                {
                    if(pEventLeagueItem->gender != requestFilterByGender)
                    {
                        continue;
                    }
                }

                std::string athleteName;
                AthletesMap::const_iterator iterAthlete = athletesMap.find(pEventLeagueItem->athleteID);
                if(iterAthlete != athletesMap.end())
                {
                    Athlete* pAthelete = static_cast<Athlete*>(iterAthlete->second);
                    athleteName = pAthelete->first_name + " " + pAthelete->last_name;
                }

                responseStream << "<tr>\n";
                if(requestFilterByGender.empty())
                {
                    responseStream << "<td>" + Poco::NumberFormatter::format(pEventLeagueItem->position) + "</td>";
                }
                else
                {
                    responseStream << "<td>" + Poco::NumberFormatter::format(pEventLeagueItem->genderPosition) + "</td>";
                }
                responseStream << "<td><a href=\"/athlete?e=" + event.name + "&a=" + Poco::NumberFormatter::format(pEventLeagueItem->athleteID)
                                    + "&y=" + Poco::NumberFormatter::format(requestFilterByYear) + "\">" + athleteName + "</a></td>";
                responseStream << "<td>" + Poco::NumberFormatter::format(pEventLeagueItem->points) + "</td>";
                responseStream << "<td>" + Poco::NumberFormatter::format(pEventLeagueItem->runCount) + "</td>";
                responseStream << "</tr>\n";
            }
            responseStream << "</table>\n";
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

