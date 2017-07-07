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
        std::string pageTitle = "Gotta love ParkRun!";

        responseStream << getHeader(pageTitle, true, additionalHeader);

        responseStream << "<p>In February 2017 ParkRun <a href=\"http://www.parkrun.com/news/2016/11/25/points-league-announcement/\">turned off its Points League web pages</a>. If you enjoyed the Points League and want to continue following it, then PRPL is for you.</p>\n";

        responseStream << "<div class=\"event-select-label\" >Select your event to view its league : </div>\n";
        responseStream << "<div class=\"events-large\" ><select name=\"events\" id=\"events-large\" >\n";

        Events::const_iterator iterEvent;
        for(iterEvent = events.begin(); iterEvent != events.end(); ++iterEvent)
        {
            const Event* pEvent = static_cast<Event*>(*iterEvent);

            responseStream << "<option value=\""<< pEvent->name << "\">"<< pEvent->name << "</option>\n";
        }

        responseStream << "</select></div>\n";

        responseStream << "<p>PRPL respects ParkRuns decisions and hopes to fill the void without offending or contradicting ParkRuns goals.</p>\n";

        responseStream << "<p>If you prefer not to see your athelete name on this site, just drop us an email and we'll remove you.</p>\n";

        responseStream << "</body></html>\n";

        EventDataModel::free(events);
	}
	catch (Poco::Exception& e)
	{
		poco_error_f2(Poco::Logger::root(), "HTTP request %s had error %s", request.getURI(), e.displayText());
		responseProblem(request, response, "ParkRun Points League", "Something bad happened");
	}
}
