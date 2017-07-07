#ifndef FileRequestHandler_INCLUDED
#define FileRequestHandler_INCLUDED

#include <Poco/Net/HTTPRequestHandler.h>
#include <Poco/Net/HTTPServerRequest.h>
#include <Poco/Net/HTTPServerResponse.h>

#include "BaseHandler.h"

#include "../Common.h"

class FileRequestHandler: public BaseHandler
{
public:
	void handleRequest(Poco::Net::HTTPServerRequest& request, Poco::Net::HTTPServerResponse& response);
    std::string getContentType(const std::string& requestURI, bool& binaryFile) const;
};

#endif // FileRequestHandler_INCLUDED
