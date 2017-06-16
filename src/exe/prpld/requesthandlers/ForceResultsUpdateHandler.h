#ifndef ForceResultsUpdateHandler_INCLUDED
#define ForceResultsUpdateHandler_INCLUDED

#include <Poco/Net/HTTPRequestHandler.h>
#include <Poco/Net/HTTPServerRequest.h>
#include <Poco/Net/HTTPServerResponse.h>

#include "../Common.h"

class ForceResultsUpdateHandler: public Poco::Net::HTTPRequestHandler
{
public:
	void handleRequest(Poco::Net::HTTPServerRequest& request, Poco::Net::HTTPServerResponse& response);
};

#endif // ForceResultsUpdateHandler_INCLUDED
