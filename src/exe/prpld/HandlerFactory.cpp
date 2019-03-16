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
#include "HandlerFactory.h"

#include "requesthandlers/AthleteHandler.h"
#include "requesthandlers/EventLeagueHandler.h"
#include "requesthandlers/GetLatestResultHandler.h"
#include "requesthandlers/ForceResultsUpdateHandler.h"
#include "requesthandlers/FileRequestHandler.h"
#include "requesthandlers/HomePageHandler.h"

#include <Poco/Logger.h>
#include <Poco/URI.h>

HandlerFactory::HandlerFactory ()
{
}

Poco::Net::HTTPRequestHandler * HandlerFactory::createRequestHandler (const Poco::Net::HTTPServerRequest &request)
{
    const std::string& requestURI = request.getURI();

	poco_debug(Poco::Logger::root(), "HTTP Request for " + requestURI);

    std::vector<std::string> uriSegments;
    Poco::URI uri(requestURI);
    uri.getPathSegments(uriSegments);

	if(uriSegments.size() == 0)
    {
        return new HomePageHandler();
    }
    else
    {
        if(uriSegments[0] == "getlatestresult")
        {
            return new GetLatestResultHandler();
        }
        else if(uriSegments[0] == "league")
        {
            return new EventLeagueHandler();
        }
        else if(uriSegments[0] == "athlete")
        {
            return new AthleteHandler();
        }
        else if(uriSegments[0] == "forceupdate")
        {
            return new ForceResultsUpdateHandler();
        }
        else
        {
            return new FileRequestHandler();
        }
    }

	return NULL;
}
