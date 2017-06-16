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
