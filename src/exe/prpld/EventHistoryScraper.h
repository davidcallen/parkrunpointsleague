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
