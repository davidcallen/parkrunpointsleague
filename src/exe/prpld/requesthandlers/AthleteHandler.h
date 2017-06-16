#ifndef AthleteHandler_INCLUDED
#define AthleteHandler_INCLUDED

#include "BaseHandler.h"

#include <Poco/Net/HTTPRequestHandler.h>
#include <Poco/Net/HTTPServerRequest.h>
#include <Poco/Net/HTTPServerResponse.h>

#include "../Common.h"

class AthleteHandler: public BaseHandler
{
public:
	void handleRequest(Poco::Net::HTTPServerRequest& request, Poco::Net::HTTPServerResponse& response);

protected:
    void responseProblem(Poco::Net::HTTPServerRequest& request, Poco::Net::HTTPServerResponse& response, const std::string& message);

};

#endif // AthleteHandler_INCLUDED
