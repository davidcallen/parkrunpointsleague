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
#include "Scraper.h"

#include "ResultsCache.h"

#include <Poco/String.h>

#include <Poco/DateTime.h>
#include <Poco/DateTimeFormatter.h>
#include <Poco/DateTimeFormat.h>
#include <Poco/DateTimeParser.h>
#include <Poco/Timespan.h>

#include <Poco/Logger.h>

#include <Poco/URI.h>
#include <Poco/Net/HTTPClientSession.h>

#include <Poco/StreamCopier.h>
#include <Poco/NullStream.h>

#include <Poco/NumberParser.h>
#include <Poco/NumberFormatter.h>

#include <Poco/Util/Application.h>

#include <gumbo.h>

#include <tidy.h>
#include <tidybuffio.h>

#include <iostream>
#include <fstream>
#include <sstream>
#include <memory>
#include <algorithm>

Scraper::Scraper()
	: _debugHTML(false),
	_traceHTML(false)
{
	_debugHTML = Poco::Util::Application::instance().config().getBool("logging.debug-html", false);
	_traceHTML = Poco::Util::Application::instance().config().getBool("logging.trace-html", false);
}

VIRTUAL Scraper::~Scraper()
{
}

VIRTUAL void Scraper::getHTML(std::string& html)
{
	html.assign(_html);
}

VIRTUAL void Scraper::getTidyHTML(std::string& html)
{
	html.assign(_tidyHtml);
}


VIRTUAL bool Scraper::getPageHTTPrequest(const std::string& url)
{
	Poco::URI uri(url);

	Poco::Net::HTTPClientSession httpClientSession(uri.getHost(), uri.getPort());

	Poco::Net::HTTPRequest httpRequest(Poco::Net::HTTPRequest::HTTP_GET, uri.getPathAndQuery(), Poco::Net::HTTPMessage::HTTP_1_1);

	poco_debug(Poco::Logger::root(), "Fetching page : " + url);

	// std::ostream & responseStream = httpClientSession.sendRequest(httpRequest);

	Poco::Net::HTTPResponse httpResponse;
	std::stringstream responseStream(std::ios_base::in | std::ios_base::out);
	if (doRequest(httpClientSession, httpRequest, httpResponse, responseStream))
	{
		poco_debug(Poco::Logger::root(), "Page fetched [" + url + "]");

		_html = responseStream.str();
		if(_traceHTML) { poco_information(Poco::Logger::root(), _html); }

		tidyHTML();

		return (!_html.empty());
	}
	else
	{
		poco_debug(Poco::Logger::root(), "Page FAILED to fetch [" + url + "]");

		return false;
	}

	return false;
}

VIRTUAL bool Scraper::doRequest(Poco::Net::HTTPClientSession& session, Poco::Net::HTTPRequest& request,
									Poco::Net::HTTPResponse& httpResponse, std::stringstream& responseStream)
{
	try
	{
		request.add("User-Agent", "User-Agent:Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.75 Safari/537.36");
		session.sendRequest(request);
		std::istream& rs = session.receiveResponse(httpResponse);

		if (httpResponse.getStatus() == Poco::Net::HTTPResponse::HTTP_OK)
		{
			Poco::StreamCopier::copyStream(rs, responseStream);

			return true;
		}
		else
		{
			poco_error(Poco::Logger::root(), "HTTP Page fetch not OK with status [" + Poco::NumberFormatter::format(httpResponse.getStatus()) + " " + httpResponse.getReason() + "]");

			Poco::NullOutputStream null;
			Poco::StreamCopier::copyStream(rs, null);

			return false;
		}
	}
	catch (Poco::Exception& e)
	{
		poco_error_f2(Poco::Logger::root(), "HTTP get of %s had error %s", request.getURI(), e.displayText());

		return false;
	}
}

VIRTUAL bool Scraper::timespanParse(const std::string& timespanStr, Poco::Timespan& timespan)
{
	unsigned int seconds = 0;
	unsigned int minutes = 0;
	unsigned int hours = 0;
	bool result = true;

	// 0123456
	// 1:15:59
	std::string timespanStrTemp = timespanStr;

	size_t durationDelimiterPos = timespanStrTemp.rfind(":");
	if(durationDelimiterPos != std::string::npos)
	{
		result = Poco::NumberParser::tryParseUnsigned(timespanStrTemp.substr(durationDelimiterPos + 1), seconds);

		timespanStrTemp = timespanStrTemp.substr(0, durationDelimiterPos);

		durationDelimiterPos = timespanStrTemp.rfind(":", durationDelimiterPos);
		if(durationDelimiterPos != std::string::npos)
		{
			result = Poco::NumberParser::tryParseUnsigned(timespanStrTemp.substr(durationDelimiterPos + 1), minutes);

			timespanStrTemp = timespanStrTemp.substr(0, durationDelimiterPos);

			durationDelimiterPos = timespanStrTemp.rfind(":", durationDelimiterPos);
			if(durationDelimiterPos != std::string::npos)
			{
				result = Poco::NumberParser::tryParseUnsigned(timespanStrTemp.substr(durationDelimiterPos + 1), hours);
			}
		}
		else
		{
			result = Poco::NumberParser::tryParseUnsigned(timespanStrTemp, minutes);
		}
	}
	timespan.assign(0, hours, minutes, seconds, 0);

	return result;
}

VIRTUAL GumboNode* Scraper::findChildNodeByTag(const GumboNode* pSearchNode, const GumboTag tag)
{
	// Find <div
	const GumboVector* searchChildren = &pSearchNode->v.element.children;
	for (unsigned int i = 0; i < searchChildren->length; ++i)
	{
		GumboNode* pChild = static_cast<GumboNode*>(searchChildren->data[i]);

		if (pChild->type == GUMBO_NODE_ELEMENT)
		{
			if(_debugHTML)
			{
				poco_information_f3(Poco::Logger::root(), "Searching in Node %s for a %s (%u)",
									std::string(gumbo_normalized_tagname(pSearchNode->v.element.tag)),
									std::string(gumbo_normalized_tagname(tag)),
									i);
			}
			if(_traceHTML)
			{
				printAttributes(pChild);
			}

			if(pChild->v.element.tag == tag)
			{
				return pChild;
			}
		}
	}
	return NULL;
}

VIRTUAL GumboNode* Scraper::findChildNodeByTagAndId(const GumboNode* pSearchNode, const GumboTag tag, const char* id)
{
	// Find <div id="foo"
	const GumboVector* searchChildren = &pSearchNode->v.element.children;
	for (unsigned int i = 0; i < searchChildren->length; ++i)
	{
		GumboNode* pChild = static_cast<GumboNode*>(searchChildren->data[i]);

		if (pChild->type == GUMBO_NODE_ELEMENT)
		{
			if(_debugHTML)
			{
				poco_information_f3(Poco::Logger::root(), "Searching for Node %s. Checking Node %s (%h)",
									std::string(gumbo_normalized_tagname(tag)),
									std::string(gumbo_normalized_tagname(pChild->v.element.tag)),
									i);
			}
			if(_traceHTML)
			{
				printAttributes(pChild);
			}

			if(pChild->v.element.tag == tag)
			{
				GumboAttribute* idAttr = gumbo_get_attribute(&pChild->v.element.attributes, "id");
				if (idAttr != NULL && strncmp(idAttr->value, id, 1000) == 0)
				{
					return pChild;
				}
			}
		}
	}
	return NULL;
}

VIRTUAL const char* Scraper::getNodeText(const GumboNode* node)
{
	if (node->type == GUMBO_NODE_ELEMENT)
	{
		const GumboVector* searchChildren = &node->v.element.children;
		for (unsigned int i = 0; i < searchChildren->length; ++i)
		{
			GumboNode* pChild = static_cast<GumboNode*>(searchChildren->data[i]);

			if (pChild->type == GUMBO_NODE_TEXT)
			{
				if(_traceHTML)
				{
					printAttributes(pChild);
				}

				// TODO : trim and remove newlines
				GumboText textNode = pChild->v.text;

				return textNode.text;
			}
		}
	}
	return NULL;
}

VIRTUAL void Scraper::printAttributes(const GumboNode* node)
{
	if (node->type == GUMBO_NODE_ELEMENT)
	{
		const GumboVector * attribs = &node->v.element.attributes;
		for (unsigned int i = 0; i < attribs->length; ++i)
		{
			GumboAttribute* attr = static_cast<GumboAttribute*>(attribs->data[i]);
			poco_information_f3(Poco::Logger::root(), "Node %s has Attribute %s=%s",
								std::string(gumbo_normalized_tagname(node->v.element.tag)),
								std::string(attr->name), std::string(attr->value));
		}
	}
}
VIRTUAL bool Scraper::tidyHTML()
{
	const char* input = _html.c_str(); // "<title>Foo</title><p>Foo!";
	TidyBuffer output = {0};
	TidyBuffer errbuf = {0};
	int rc = -1;
	Bool ok;

	TidyDoc tdoc = tidyCreate();					 // Initialize "document"
	// printf( "Tidying:\t%s\n", input );

	ok = tidyOptSetBool( tdoc, TidyXhtmlOut, no );  // Convert to XHTML
	if ( ok )
		rc = tidySetErrorBuffer( tdoc, &errbuf );	  // Capture diagnostics
	if ( rc >= 0 )
		rc = tidyParseString( tdoc, input );		   // Parse the input
	if ( rc >= 0 )									// Set No wrapping
		rc = ( tidyOptSetInt(tdoc, TidyWrapLen, 10000) ? rc : -1 );
	if ( rc >= 0 )									// Set No wrapping
		rc = ( tidyOptSetBool(tdoc, TidyWrapAttVals, no) ? rc : -1 );
	if ( rc >= 0 )
		rc = tidyCleanAndRepair( tdoc );			   // Tidy it up!
	if ( rc >= 0 )
		rc = tidyRunDiagnostics( tdoc );			   // Kvetch
	if ( rc > 1 )									// If error, force output.
		rc = ( tidyOptSetBool(tdoc, TidyForceOutput, yes) ? rc : -1 );
	if ( rc >= 0 )
		rc = tidySaveBuffer( tdoc, &output );		  // Pretty Print

	if ( rc >= 0 )
	{
		if ( rc > 0 )
		{
			if(_traceHTML)
			{
				poco_information_f1(Poco::Logger::root(), "HTML Tidy diagnostics :\n\n%s", errbuf.bp);
			}
		}
		if(output.bp != NULL)
		{
			if(_traceHTML)
			{
				poco_information_f1(Poco::Logger::root(), "HTML Tidy output :\n\n%s", output.bp);
			}
			_tidyHtml.assign((char*)output.bp);
		}
	}
	else
	{
		poco_error_f1(Poco::Logger::root(), "HTML Tidy error :\n\n%h", rc);
	}

	tidyBufFree( &output );
	tidyBufFree( &errbuf );
	tidyRelease( tdoc );

	return (rc >= 0);
}
