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
#ifndef Scraper_INCLUDED
#define Scraper_INCLUDED

#include <Poco/Net/HTTPRequestHandler.h>
#include <Poco/Net/HTTPServerRequest.h>
#include <Poco/Net/HTTPServerResponse.h>
#include <Poco/Net/HTTPClientSession.h>
#include <Poco/Net/HTTPRequest.h>
#include <Poco/Net/HTTPResponse.h>

#include <gumbo.h>

#include "Common.h"
#include "dataobject/Event.h"
#include "dataobject/EventResult.h"
#include "dataobject/EventResultItem.h"

class Scraper
{
public:
	Scraper();
	virtual ~Scraper();

public:
	virtual void getHTML(std::string& html);
	virtual void getTidyHTML(std::string& html);

protected:
	virtual bool getPageHTTPrequest(const std::string& url);

	virtual bool doRequest(Poco::Net::HTTPClientSession& session, Poco::Net::HTTPRequest& request, Poco::Net::HTTPResponse& httpResponse, std::stringstream& responseStream);

	virtual bool timespanParse(const std::string& timespanStr, Poco::Timespan& timespan);

	virtual GumboNode* findChildNodeByTag(const GumboNode* searchNode, const GumboTag tag);

	virtual GumboNode* findChildNodeByTagAndId(const GumboNode* searchNode, const GumboTag tag, const char* id);

	virtual const char* getNodeText(const GumboNode* node);

	virtual void printAttributes(const GumboNode* node);

	virtual bool tidyHTML();

protected:
	bool _debugHTML;
	bool _traceHTML;

	std::string _html;
	std::string _tidyHtml;
};

#endif // Scraper_INCLUDED
