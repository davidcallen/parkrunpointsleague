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
#include "HomePageHandler.h"

#include "../datamodel/EventDataModel.h"

#include <Poco/Logger.h>
#include <Poco/URI.h>
#include <Poco/Util/Application.h>

void HomePageHandler::handleRequest(Poco::Net::HTTPServerRequest& request, Poco::Net::HTTPServerResponse& response)
{
	try
	{
		response.setChunkedTransferEncoding(true);
		response.setContentType("text/html");
		response.set("cache-control", "max-age=60");

        Events events;
        EventDataModel::fetch(events);

        std::ostream& responseStream = response.send();

        std::string additionalHeader;
        additionalHeader += "  <script> \n";
        additionalHeader += "    $(document).ready(function(){ \n";
        additionalHeader += "      $( \"#events-large\" ).selectmenu({\n";
        additionalHeader += "        select: function( event, data ) {\n";
        additionalHeader += "          window.location.href = \"/league?e=\" + data.item.value;\n";
        additionalHeader += "        }\n";
        additionalHeader += "      });\n";
        additionalHeader += "    });\n";
        additionalHeader += "  </script>\n";
        std::string pageTitle = "ParkRun Points Leagues";

        responseStream << getHeader(pageTitle, true, additionalHeader);

        responseStream << "<p>In February 2017 ParkRun <a href=\"http://www.parkrun.com/news/2016/11/25/points-league-announcement/\">turned off its Points League web pages</a>. </p>\n";
        responseStream << "<p>If you enjoyed the Points League and want to continue following it, then PRPL is for you.</p>\n";

        responseStream << "<div class=\"event-select-label\" >Select your event to view its league : </div>\n";
        responseStream << "<div class=\"events-large\" ><select name=\"events\" id=\"events-large\" >\n";

        Events::const_iterator iterEvent;
        for(iterEvent = events.begin(); iterEvent != events.end(); ++iterEvent)
        {
            const Event* pEvent = static_cast<Event*>(*iterEvent);

            responseStream << "<option value=\""<< pEvent->name << "\">"<< pEvent->name << "</option>\n";
        }

        responseStream << "</select></div>\n";

        responseStream << "<p>Our goals : \n";
        responseStream << "<ul><li>Only provide the League results and not duplicate ParkRun's website functionality.</li>\n";
        responseStream << "<li>Respect ParkRun's decisions and hope to provide the League without offending or contradicting ParkRuns goals.</li>\n";
        responseStream << "<li>Respect all data - it will never be shared with any other organisations.</li></ul>\n";
        responseStream << "</p>\n";

        responseStream << "<p>If you prefer not to see your athlete name on this site, just drop us an email and we'll remove you.</p>\n";

        responseStream << "</body></html>\n";

        EventDataModel::free(events);
	}
	catch (Poco::Exception& e)
	{
		poco_error_f2(Poco::Logger::root(), "HTTP request %s had error %s", request.getURI(), e.displayText());
		responseProblem(request, response, "ParkRun Points League", "Something bad happened");
	}
}
