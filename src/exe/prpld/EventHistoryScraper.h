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
#ifndef EventHistoryScraper_INCLUDED
#define EventHistoryScraper_INCLUDED

#include <Poco/Net/HTTPRequestHandler.h>
#include <Poco/Net/HTTPServerRequest.h>
#include <Poco/Net/HTTPServerResponse.h>
#include <Poco/Net/HTTPClientSession.h>
#include <Poco/Net/HTTPRequest.h>
#include <Poco/Net/HTTPResponse.h>

#include <gumbo.h>

#include "Common.h"
#include "Scraper.h"
#include "dataobject/Event.h"
#include "dataobject/EventResult.h"
#include "dataobject/EventResultItem.h"

class EventHistoryScraper : public Scraper
{
public:
    EventHistoryScraper();
    virtual ~EventHistoryScraper();

public:
    bool execute(const Event& event);

    bool execute(const Event& event, const std::string& html);

	Event& getEvent();

	EventResults& getEventResults();

protected:
	bool getPage();

//	bool getPageHTTPrequest();

	bool parsePage(const std::string& html);

	GumboNode* parsePageFindContent(const GumboNode* pRootNode);

	GumboNode* parsePageFindTable(const GumboNode* pContentNode);

	bool parseResultsTable(const GumboNode* pTableNode);

	bool parseTableDataResultNumber(const GumboNode* pTableDataNode, std::string& resultNumberStr);

    bool parseTableDataDate(const GumboNode* pTableDataNode, std::string& resultDateStr, Poco::DateTime& resultDate);

protected:
	std::string _html;

private:
	Event _event;
	EventResults _eventResults;
};

#endif // EventHistoryScraper_INCLUDED
