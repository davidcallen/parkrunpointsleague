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

	poco_trace(Poco::Logger::root(), "HTTP Request for " + requestURI);

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
