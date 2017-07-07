#ifndef GetLatestResultHandler_INCLUDED
#define GetLatestResultHandler_INCLUDED

#include <Poco/Net/HTTPRequestHandler.h>
#include <Poco/Net/HTTPServerRequest.h>
#include <Poco/Net/HTTPServerResponse.h>

#include "BaseHandler.h"

#include "../Common.h"

class GetLatestResultHandler: public BaseHandler
{
public:
	void handleRequest(Poco::Net::HTTPServerRequest& request, Poco::Net::HTTPServerResponse& response);
};

#endif // GetLatestResultHandler_INCLUDED
