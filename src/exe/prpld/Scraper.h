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
