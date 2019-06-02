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
#include "ForceResultsUpdateHandler.h"
#include "../ResultsController.h"

#include "../dataobject/Event.h"
#include "../datamodel/EventDataModel.h"
#include "../dataobject/EventResult.h"
#include "../datamodel/EventResultDataModel.h"
#include "../datamodel/EventResultItemDataModel.h"

#include <Poco/DateTime.h>
#include <Poco/DateTimeFormatter.h>
#include <Poco/DateTimeFormat.h>
#include <Poco/Timespan.h>

#include <Poco/Logger.h>

#include <Poco/ThreadLocal.h>

#include <Poco/Util/Application.h>

void ForceResultsUpdateHandler::handleRequest(Poco::Net::HTTPServerRequest& request, Poco::Net::HTTPServerResponse& response)
{
	try
	{
		response.setChunkedTransferEncoding(true);
		response.setContentType("text/html");

		Poco::DateTime now;
		std::string timeString(Poco::DateTimeFormatter::format(now, Poco::DateTimeFormat::SORTABLE_FORMAT));

		std::ostream& responseStream = response.send();
		responseStream << "<html><head><head><title>ParkRun Points League</title></head>";
		responseStream << "<body><p>ParkRun results fetching</p>";
		responseStream << "<p></p>";
		responseStream << "</body></html>";

		ResultsController resultsController;
		resultsController.process("miltonkeynes");
	}
	catch (Poco::Exception& e)
	{
		poco_error_f2(Poco::Logger::root(), "HTTP request %s had error %s", request.getURI(), e.displayText());
		responseProblem(request, response, "Force results update", "Something bad happened");
	}
}
