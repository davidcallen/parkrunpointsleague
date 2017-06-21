#include "BaseHandler.h"

#include <Poco/DateTime.h>
#include <Poco/DateTimeFormatter.h>
#include <Poco/DateTimeFormat.h>
#include <Poco/NumberFormatter.h>
#include <Poco/Timespan.h>

#include <Poco/Logger.h>
#include <Poco/URI.h>

#include <Poco/Util/Application.h>

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
    header += "  <script src=\"https://code.jquery.com/jquery-1.12.4.js\"></script>\n";
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
    header += "<body><div id=\"header\"><img src=\"/images/logo/logo-24.png\">Park Run Points Leagues</div>\n";
    header += "<h1>" + pageTitle + "</h1>\n";

    return header;
}

void BaseHandler::responseProblem(Poco::Net::HTTPServerRequest& request, Poco::Net::HTTPServerResponse& response, const std::string& pageTitle, const std::string& message)
{
    std::ostream& responseStream = response.send();
    responseStream << getHeader(pageTitle, false, "") << "</head>\n";
    responseStream << "<body><h1>Oops found a problem</h1>\n";
    responseStream << "<p>" << message << "</p>\n";
    responseStream << "</body></html>\n";
}

