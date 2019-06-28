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
#include "HealthPageHandler.h"

#include "../datamodel/EventDataModel.h"

#include <Poco/Logger.h>
#include <Poco/URI.h>
#include <Poco/Util/Application.h>

void HealthPageHandler::handleRequest(Poco::Net::HTTPServerRequest& request, Poco::Net::HTTPServerResponse& response)
{
	try
	{
		response.setChunkedTransferEncoding(true);
		response.setContentType("text/html");
		response.set("cache-control", "max-age=60");

		Events events;
		EventDataModel::fetch(events);

		if(events.size() == 0)
		{
			response.setStatus(Poco::Net::HTTPServerResponse::HTTP_GONE);
		}

		std::ostream& responseStream = response.send();

		std::string pageTitle = "ParkRun Points Leagues";
		responseStream << getHeader(pageTitle, true, "");
		responseStream << "OK";
		responseStream << getFooter();
		
		EventDataModel::free(events);
	}
	catch (Poco::Exception& e)
	{
		poco_error_f2(Poco::Logger::root(), "HTTP request %s had error %s", request.getURI(), e.displayText());
		response.setStatus(Poco::Net::HTTPServerResponse::HTTP_GONE);
		responseProblem(request, response, "ParkRun Points League", "Something bad happened");
	}
}
