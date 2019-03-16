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
#include "FileRequestHandler.h"

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

        const std::string fileNameAndPath("../assets/" + requestURI);

        response.sendFile(fileNameAndPath, requestURIcontentType);
	}
	catch (Poco::Exception& e)
	{
	    response.setStatusAndReason(Poco::Net::HTTPResponse::HTTP_NOT_FOUND, Poco::Net::HTTPResponse::HTTP_REASON_NOT_FOUND);
	    response.send();

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
