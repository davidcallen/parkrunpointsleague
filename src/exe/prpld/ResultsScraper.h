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
#ifndef ResultsScraper_INCLUDED
#define ResultsScraper_INCLUDED

#include <Poco/Net/HTTPRequestHandler.h>
#include <Poco/Net/HTTPServerRequest.h>
#include <Poco/Net/HTTPServerResponse.h>
#include <Poco/Net/HTTPClientSession.h>
#include <Poco/Net/HTTPRequest.h>
#include <Poco/Net/HTTPResponse.h>

#include <gumbo.h>

#include "Common.h"
#include "Scraper.h"
#include "dataobject/Athlete.h"
#include "dataobject/Event.h"
#include "dataobject/EventResult.h"
#include "dataobject/EventResultItem.h"

class ResultsScraper : public Scraper
{
public:
	ResultsScraper();
	virtual ~ResultsScraper();

public:
	bool execute(const Event& event, const EventResult& eventResult);
	bool execute(const Event& event, const EventResult& eventResult, const std::string& html);

	Event getEvent();
	EventResult getEventResult();
	EventResultItems getEventResultItems();
	Athletes getAthletes();

protected:
	bool getPage();
//	bool getPageHTTPrequest();
	bool parsePage(const std::string& html);
	GumboNode* parsePageFindContent(const GumboNode* pRootNode);
	GumboNode* parsePageFindTable(const GumboNode* pContentNode);
	bool parseContentNode(const GumboNode* pContentNode);
	bool parseContentDataTitle(const GumboNode* pTitleDataNode);
	bool parseResultsTable(const GumboNode* pTableNode);
	bool parseTableDataPosition(const GumboNode* pTableDataNode, std::string& positionStr);
	bool parseTableDataAthlete(const GumboNode* pTableDataNode, std::string& athleteNumberStr, std::string& athleteName);
	bool parseTableDataDuration(const GumboNode* pTableDataNode, std::string& durationStr);
	bool parseTableDataGender(const GumboNode* pTableDataNode, std::string& genderStr);
	bool parseTableDataGenderPosition(const GumboNode* pTableDataNode, std::string& genderPositionStr);

private:
	Event _event;
	EventResult _eventResult;
	EventResultItems _eventResultItems;
	Athletes _athletes;
};

#endif // ResultsScraper_INCLUDED
