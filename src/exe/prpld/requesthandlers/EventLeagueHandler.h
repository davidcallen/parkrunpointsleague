#ifndef EventLeagueHandler_INCLUDED
#define EventLeagueHandler_INCLUDED

#include <Poco/Net/HTTPRequestHandler.h>
#include <Poco/Net/HTTPServerRequest.h>
#include <Poco/Net/HTTPServerResponse.h>

#include "BaseHandler.h"

#include "../Common.h"

class EventLeagueHandler: public BaseHandler
{
public:
	void handleRequest(Poco::Net::HTTPServerRequest& request, Poco::Net::HTTPServerResponse& response);
};

#endif // EventLeagueHandler_INCLUDED
