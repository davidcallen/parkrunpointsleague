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

        std::vector<std::string> uriSegments;
        Poco::URI uri(requestURI);
        uri.getPathSegments(uriSegments);


		response.setChunkedTransferEncoding(true);
		response.setContentType("text/html");

        // Get query arguments
        unsigned athleteID = 0;
        std::string eventName = "";
        unsigned int year = 0;
        if(uriSegments.size() > 1)
        {
            eventName = uriSegments[1];
        }
        if(uriSegments.size() > 2)
        {
            if(!Poco::NumberParser::tryParseUnsigned(uriSegments[2], athleteID))
            {
                responseProblem(request, response, "Unknown athlete ID");

                return;
            }
        }
        Poco::URI::QueryParameters queryParameters = uri.getQueryParameters();
        Poco::URI::QueryParameters::const_iterator iterQueryParams;
        for(iterQueryParams = queryParameters.begin(); iterQueryParams != queryParameters.end(); ++iterQueryParams)
        {
			if(iterQueryParams->first == "year")
			{
				unsigned int yearTemp = 0;
				if(Poco::NumberParser::tryParseUnsigned(iterQueryParams->second, yearTemp))
				{
					year = yearTemp;
				}
			}
		}

        bool validateOK = true;

		Event event;
		if(!EventDataModel::fetch(eventName, event))
		{
		    responseProblem(request, response, "Sorry, this ParkRun is not currently in our database.");
		    validateOK = false;
		}
		Athlete athlete;
		if(!AthleteDataModel::fetch(athleteID, athlete))
		{
		    responseProblem(request, response, "Sorry, this Athlete is not currently in our database.");
		    validateOK = false;
		}

		if(validateOK)
		{
		    // Fetch EventLeagues in Year Desc order
            EventLeagues eventLeagues;
            EventLeagueDataModel::fetch(event.ID, eventLeagues);

			// Find the index of the League for specified query year, so can open accordian tab for this year.
			unsigned long indexOfLeagueForYear = 0;
			bool foundIndexOfLeagueForYear = false;
			if(year != 0)
			{
				EventLeagues::const_iterator iterLeague;
				for(iterLeague = eventLeagues.begin(); iterLeague != eventLeagues.end(); ++iterLeague)
				{
					EventLeague* pEventLeague = static_cast<EventLeague*>(*iterLeague);
					if(pEventLeague->year == year)
					{
						foundIndexOfLeagueForYear = true;
						break;
					}
					indexOfLeagueForYear++;
				}
			}

            std::ostream& responseStream = response.send();

            std::string additionalHeader;
            additionalHeader += "  <script> \n";
            additionalHeader += "    $(document).ready(function(){ \n";
            additionalHeader += "      $(\"#athlete-event-league\").accordion({ \n";
            additionalHeader += "        collapsible: true, \n";
            if(foundIndexOfLeagueForYear)
            {
				additionalHeader += "        active: " + Poco::NumberFormatter::format(indexOfLeagueForYear) + ",\n";
			}
			else
			{
				additionalHeader += "        active: false,\n";
			}
            additionalHeader += "        heightStyle: 'content'\n";
            additionalHeader += "      }); \n";
            additionalHeader += "    }); \n";
            additionalHeader += "  </script> \n";

            std::string pageTitle = athlete.first_name + " " + athlete.last_name + " league positions for " + event.title ;
            responseStream << getHeader(pageTitle, true, additionalHeader);

            responseStream << "<div id='athlete-event-league'>\n";
            EventLeagues::const_iterator iterLeague;
            for(iterLeague = eventLeagues.begin(); iterLeague != eventLeagues.end(); ++iterLeague)
            {
                EventLeague* pEventLeague = static_cast<EventLeague*>(*iterLeague);

                EventLeagueItem eventLeagueItem;
                if(EventLeagueItemDataModel::fetch(pEventLeague->ID, athleteID, eventLeagueItem))
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
                    responseStream << "</tr>\n";

                    EventResults eventResults;
                    EventResultDataModel::fetch(event.ID, pEventLeague->year, eventResults);
                    EventResults::const_iterator iterEventResult;
                    for(iterEventResult = eventResults.begin(); iterEventResult != eventResults.end(); ++iterEventResult)
                    {
                        EventResult* pEventResult = static_cast<EventResult*>(*iterEventResult);

                        EventResultItem eventResultItem;
                        if(EventResultItemDataModel::fetch(pEventResult->ID, athleteID, eventResultItem))
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
                            responseStream << "</tr>\n";
                        }
                    }
                    responseStream << "</table>\n";
                    responseStream << "</div>\n";
                }
            }
            responseStream << "</div>\n";

            responseStream << "</body></html>\n";

            EventLeagueDataModel::free(eventLeagues);
		}

	}
	catch (Poco::Exception& e)
	{
//		std::cerr << e.displayText() << std::endl;
		poco_error_f2(Poco::Logger::root(), "HTTP request %s had error %s", request.getURI(), e.displayText());
		responseProblem(request, response, "Something bad happened");
	}
}

void AthleteHandler::responseProblem(Poco::Net::HTTPServerRequest& request, Poco::Net::HTTPServerResponse& response, const std::string& message)
{
    std::ostream& responseStream = response.send();
    responseStream << "<html><head><head><title>ParkRun Points League</title></head>";
    responseStream << "<body><h1>Oops found a problem</h1>";
    responseStream << "<p>" << message << "</p>";
    responseStream << "</body></html>";
}
