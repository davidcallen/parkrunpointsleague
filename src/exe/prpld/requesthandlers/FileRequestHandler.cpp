#include "FileRequestHandler.h"
#include "../ResultsController.h"

#include "../datamodel/EventDataModel.h"
#include "../datamodel/EventLeagueDataModel.h"
#include "../datamodel/AthleteDataModel.h"

#include <Poco/DateTime.h>
#include <Poco/DateTimeFormatter.h>
#include <Poco/DateTimeFormat.h>
#include <Poco/NumberFormatter.h>
#include <Poco/Timespan.h>
#include <Poco/Base64Encoder.h>

#include <Poco/Logger.h>

#include <Poco/ThreadLocal.h>

#include <Poco/Util/Application.h>

#include <ostream>
#include <fstream>

void FileRequestHandler::handleRequest(Poco::Net::HTTPServerRequest& request, Poco::Net::HTTPServerResponse& response)
{
	try
	{
        const std::string& requestURI = request.getURI();
        bool isBinaryFile;
        const std::string requestURIcontentType = getContentType(requestURI, isBinaryFile);

        const std::string fileNameAndPath("/mnt/hdd/d/prpl/trunk/assets/" + requestURI);
/*
isBinaryFile = false;
        if(isBinaryFile)
        {
            std::ostringstream ostr;
            Poco::Base64Encoder base64encoder(ostr);

            std::ifstream inputFileStream(fileNameAndPath.c_str(), std::ios_base::in);
            std::copy(std::istreambuf_iterator<char>(inputFileStream),
                        std::istreambuf_iterator<char>(),
                        std::ostreambuf_iterator<char>(base64encoder));
            base64encoder.close();
            //response.setChunkedTransferEncoding(true);
            response.setContentType(requestURIcontentType);

            std::string output(ostr.str());
            response.sendBuffer(output.c_str(), output.size());
        }
        else
        {
*/
            response.sendFile(fileNameAndPath, requestURIcontentType);
//        }
	}
	catch (Poco::Exception& e)
	{
	    response.setStatusAndReason(Poco::Net::HTTPResponse::HTTP_NOT_FOUND, Poco::Net::HTTPResponse::HTTP_REASON_NOT_FOUND);
	    response.send();

//		std::cerr << e.displayText() << std::endl;
		poco_error_f2(Poco::Logger::root(), "HTTP request %s had error %s", request.getURI(), e.displayText());
	}
}

std::string FileRequestHandler::getContentType(const std::string& requestURI, bool& isBinaryFile) const
{
    isBinaryFile = false;

    size_t dotDelimPos = requestURI.rfind(".");
    if(dotDelimPos != std::string::npos)
    {
        std::string fileExtension = requestURI.substr(dotDelimPos + 1);
		if (fileExtension == "jpg" || fileExtension == "jpeg")
        {
            isBinaryFile = true;
			return "image/jpeg";
        }
		else if (fileExtension == "png")
        {
            isBinaryFile = true;
			return "image/png";
        }
		else if (fileExtension == "gif")
        {
            isBinaryFile = true;
			return "image/gif";
        }
		else if (fileExtension == "ico")
        {
            isBinaryFile = true;
			return "image/x-icon";
        }
		else if (fileExtension == "htm")
        {
            isBinaryFile = false;
			return "text/html";
        }
		else if (fileExtension == "html")
        {
            isBinaryFile = false;
			return "text/html";
        }
		else if (fileExtension == "css")
        {
            isBinaryFile = false;
			return "text/css";
        }
		else if (fileExtension == "js")
        {
            isBinaryFile = false;
			return "application/javascript";
        }
		else if (fileExtension == "xml")
        {
            isBinaryFile = false;
			return "text/xml";
        }
		else
        {
            isBinaryFile = true;
			return "application/binary";
        }
    }

    return "text/html";  // Best guess !
}
