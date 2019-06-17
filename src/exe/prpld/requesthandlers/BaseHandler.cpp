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
#include "BaseHandler.h"
#include "../PRPLHTTPServerApplication.h"

#include <Poco/DateTime.h>
#include <Poco/DateTimeFormatter.h>
#include <Poco/DateTimeFormat.h>
#include <Poco/Environment.h>
#include <Poco/NumberFormatter.h>
#include <Poco/Timespan.h>

#include <Poco/Logger.h>
#include <Poco/URI.h>

#include <Poco/Util/Application.h>

BaseHandler::BaseHandler() :
	_showHostName(false)
{
	_showHostName = Poco::Util::Application::instance().config().getBool("logging.show-hostname", false);
	if(Poco::Environment::has("PRPL_LOGGING_SHOW_HOSTNAME"))
	{
		_showHostName = Poco::NumberParser::parseBool(Poco::Environment::get("PRPL_LOGGING_SHOW_HOSTNAME"));
	}
}

std::string BaseHandler::getHeader(const std::string& pageTitle, const bool includeJQuery, const std::string& additionalHeader) const
{
	bool useOurJQueryFiles = true;
	bool useMinifiedJQueryFiles = false;
	std::string minify;
	if(useMinifiedJQueryFiles)
	{
		minify = ".min";
	}
	std::string header;
	header = "<html><head><title>ParkRun Points League</title>\n";
	header += "<link rel=\"stylesheet\" type=\"text/css\" href=\"/css/style.css\" type=\"text/css\"></link>\n";
	header += "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n";
	header += "  <script src=\"https://code.jquery.com/jquery-1.12.4" + minify + ".js\"></script>\n";
	if(useOurJQueryFiles)
	{
		header += "  <link rel=\"stylesheet\" href=\"/jquery-ui-1.12.1.custom/jquery-ui" + minify + ".css\">\n";
		header += "  <link rel=\"stylesheet\" href=\"/jquery-ui-1.12.1.custom/jquery-ui.theme" + minify + ".css\">\n";
		header += "  <link rel=\"stylesheet\" href=\"/jquery-ui-1.12.1.custom/jquery-ui.structure" + minify + ".css\">\n";
		header += "  <script src=\"/jquery-ui-1.12.1.custom/jquery-ui" + minify + ".js\"></script>\n";
	}
	else
	{
		header += "  <link rel=\"stylesheet\" href=\"//code.jquery.com/ui/1.12.1/themes/base/jquery-ui" + minify + ".css\">\n";
		header += "  <script src=\"https://code.jquery.com/ui/1.12.1/jquery-ui" + minify + ".js\"></script>\n";
	}
	header += additionalHeader + "</head>";
	header += "<body><div id=\"header\"><a href=\"/\"><img src=\"/images/logo/logo-24.png\">ParkRun Points Leagues</a></div>\n";
	header += "<h1>" + pageTitle + "</h1>\n";
	header += "<div class=\"content\">\n";

	return header;
}

std::string BaseHandler::getFooter() const
{
	std::string footer;
	footer += "</div> <!-- class=\"content\" -->\n";
	if(_showHostName)
	{
		footer += PRPLHTTPServerApplication::instance().getHostName();
	}
	footer += "</body></html>\n";

	return footer;
}

void BaseHandler::responseProblem(Poco::Net::HTTPServerRequest& request, Poco::Net::HTTPServerResponse& response, const std::string& pageTitle, const std::string& message)
{
	std::ostream& responseStream = response.send();
	responseStream << getHeader(pageTitle, false, "") << "</head>\n";
	responseStream << "<body><h1>Oops found a problem</h1>\n";
	responseStream << "<p>" << message << "</p>\n";
	responseStream << getFooter();
}

