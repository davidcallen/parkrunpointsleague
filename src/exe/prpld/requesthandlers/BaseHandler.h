#ifndef BaseHandler_INCLUDED
#define BaseHandler_INCLUDED

#include <Poco/Net/HTTPRequestHandler.h>
#include <Poco/Net/HTTPServerRequest.h>
#include <Poco/Net/HTTPServerResponse.h>

#include "../Common.h"

class BaseHandler: public Poco::Net::HTTPRequestHandler
{
public:
	std::string getHeader(const std::string& pageTitle, const bool includeJQuery, const std::string& additionalHeader) const;

protected:
    void responseProblem(Poco::Net::HTTPServerRequest& request, Poco::Net::HTTPServerResponse& response,
                         const std::string& pageTitle, const std::string& message);

};

#endif // BaseHandler_INCLUDED
