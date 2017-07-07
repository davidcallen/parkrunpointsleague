#include "AthleteHandler.h"
#include "../ResultsController.h"

#include "../datamodel/EventDataModel.h"
#include "../datamodel/EventLeagueDataModel.h"
#include "../datamodel/EventLeagueItemDataModel.h"
#include "../datamodel/EventResultDataModel.h"
#include "../datamodel/EventResultItemDataModel.h"
#include "../datamodel/AthleteDataModel.h"

#include <Poco/DateTime.h>
#include <Poco/DateTimeFormatter.h>
#include <Poco/DateTimeFormat.h>
#include <Poco/NumberFormatter.h>
#include <Poco/Timespan.h>

#include <Poco/Logger.h>
#include <Poco/URI.h>

#include <Poco/Util/Application.h>

void AthleteHandler::handleRequest(Poco::Net::HTTPServerRequest& request, Poco::Net::HTTPServerResponse& response)
{
	try
	{
        const std::string& requestURI = request.getURI();
        Poco::URI uri(requestURI);

		response.setChunkedTransferEncoding(true);
		response.setContentType("text/html");
		response.set("cache-control", "max-age=0");

        // Get query arguments
        unsigned requestFilterByAthleteID = 0;
        std::string requestFilterByEventName = "";
        unsigned int requestFilterByYear = 0;

        Poco::URI::QueryParameters queryParameters = uri.getQueryParameters();
        Poco::URI::QueryParameters::const_iterator iterQueryParams;
        for(iterQueryParams = queryParameters.begin(); iterQueryParams != queryParameters.end(); ++iterQueryParams)
        {
            if(iterQueryParams->first == "e")
            {
                requestFilterByEventName = iterQueryParams->second;
            }
            else if(iterQueryParams->first == "a")
            {
                unsigned int requestFilterByAthleteIDTemp = 0;
                if(Poco::NumberParser::tryParseUnsigned(iterQueryParams->second, requestFilterByAthleteIDTemp))
                {
                    requestFilterByAthleteID = requestFilterByAthleteIDTemp;
                }
            }
			else if(iterQueryParams->first == "y")
			{
				unsigned int requestFilterByYearTemp = 0;
				if(Poco::NumberParser::tryParseUnsigned(iterQueryParams->second, requestFilterByYearTemp))
				{
					requestFilterByYear = requestFilterByYearTemp;
				}
			}
		}

        bool validateOK = true;

		Event event;
		if(!EventDataModel::fetch(requestFilterByEventName, event))
		{
		    responseProblem(request, response, "League positions", "Sorry, this ParkRun is not currently in our database.");
		    validateOK = false;
		}
		Athlete athlete;
		if(!AthleteDataModel::fetch(requestFilterByAthleteID, athlete))
		{
		    responseProblem(request, response, "League positions", "Sorry, this Athlete is not currently in our database.");
		    validateOK = false;
		}

		if(validateOK)
		{
		    // Fetch EventLeagues in Year Desc order
            EventLeagues eventLeagues;
            EventLeagueDataModel::fetch(event.ID, eventLeagues);

            std::ostream& responseStream = response.send();

            std::string additionalHeader;
            additionalHeader += "  <script> \n";
            additionalHeader += "    $(document).ready(function(){ \n";
            additionalHeader += "      $(\"#athlete-event-league\").accordion({ \n";
            additionalHeader += "        collapsible: true, \n";
			additionalHeader += "        active: false,\n";
            additionalHeader += "        heightStyle: 'content'\n";
            additionalHeader += "      }); \n";
            additionalHeader += "    }); \n";
            additionalHeader += "  </script> \n";

            std::string pageTitle = athlete.first_name + " " + athlete.last_name + " league positions for " + event.title ;
            responseStream << getHeader(pageTitle, true, additionalHeader);

			unsigned long accordionIndexOfLeagueForYear = 0;
            unsigned long leagueIndex = 0;

            responseStream << "<div id='athlete-event-league'>\n";
            EventLeagues::const_iterator iterLeague;
            for(iterLeague = eventLeagues.begin(); iterLeague != eventLeagues.end(); ++iterLeague)
            {
                EventLeague* pEventLeague = static_cast<EventLeague*>(*iterLeague);

                EventLeagueItem eventLeagueItem;
                if(EventLeagueItemDataModel::fetch(pEventLeague->ID, requestFilterByAthleteID, eventLeagueItem))
                {
                    responseStream << "<p>Position " + Poco::NumberFormatter::format(eventLeagueItem.position) + " in " << pEventLeague->year << " with " + Poco::NumberFormatter::format(eventLeagueItem.points) + " points and " + Poco::NumberFormatter::format(eventLeagueItem.runCount) + " runs</p>\n";
                    responseStream << "<div id='athlete-event-league-results'>\n";
                    responseStream << "<table class=\"with-border with-row-colour\" >\n";
                    responseStream << "<tr>\n";
                    responseStream << "<th>Event #</th>\n";
                    responseStream << "<th>Date</th>\n";
                    responseStream << "<th>Pos</th>\n";
                    responseStream << "<th>Gender Pos</th>\n";
                    responseStream << "<th>Time</th>\n";
                    responseStream << "<th>Points</th>\n";
                    responseStream << "</tr>\n";

                    EventResults eventResults;
                    EventResultDataModel::fetch(event.ID, pEventLeague->year, eventResults);
                    EventResults::const_iterator iterEventResult;
                    for(iterEventResult = eventResults.begin(); iterEventResult != eventResults.end(); ++iterEventResult)
                    {
                        EventResult* pEventResult = static_cast<EventResult*>(*iterEventResult);

                        EventResultItem eventResultItem;
                        if(EventResultItemDataModel::fetch(pEventResult->ID, requestFilterByAthleteID, eventResultItem))
                        {
                            responseStream << "<tr>\n";
                            responseStream << "<td>" + Poco::NumberFormatter::format(pEventResult->resultNumber) + "</td>\n";
                            responseStream << "<td>" << Poco::DateTimeFormatter::format(pEventResult->date, "%d/%m/%Y") << "</td>\n";
                            responseStream << "<td>" + Poco::NumberFormatter::format(eventResultItem.position) + "</td>\n";
                            responseStream << "<td>" + Poco::NumberFormatter::format(eventResultItem.genderPosition.value()) + "</td>\n";
                            responseStream << "<td>";
                            if(!eventResultItem.durationSecs.isNull())
                            {
                                Poco::Timespan durationTimespan = eventResultItem.getDurationTimespan();

                                responseStream << Poco::DateTimeFormatter::format(durationTimespan, "%h:%M:%S");
                            }
                            responseStream << "</td>\n";
                            responseStream << "<td>" + Poco::NumberFormatter::format(EventLeagueItem::calculatePoints(eventResultItem.genderPosition.value(), 400)) + "</td>\n";
                            responseStream << "</tr>\n";
                        }
                    }
                    responseStream << "</table>\n";
                    responseStream << "</div>\n";

					if(pEventLeague->year == requestFilterByYear)
					{
                        // save the accordion index of the League for specified query year, so can expand accordian tab for this year.
						accordionIndexOfLeagueForYear = leagueIndex;
					}
                    leagueIndex++;
                }
            }
            responseStream << "</div>\n";


            // Set accordion to open on requested Year
            responseStream << "  <script> \n";
            responseStream << "    $(document).ready(function(){ \n";
            responseStream << "        $(\"#athlete-event-league\").accordion(\"option\", \"active\",  " + Poco::NumberFormatter::format(accordionIndexOfLeagueForYear) + ");\n";
            responseStream <<  "    }); \n";
            responseStream <<  "  </script> \n";

            responseStream << getFooter();

            EventLeagueDataModel::free(eventLeagues);
		}

	}
	catch (Poco::Exception& e)
	{
		poco_error_f2(Poco::Logger::root(), "HTTP request %s had error %s", request.getURI(), e.displayText());
		responseProblem(request, response, "League positions", "Something bad happened");
	}
}

