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
#include "EventHistoryScraper.h"

#include "datamodel/EventResultDataModel.h"

#include <Poco/String.h>

#include <Poco/DateTime.h>
#include <Poco/DateTimeFormatter.h>
#include <Poco/DateTimeFormat.h>
#include <Poco/DateTimeParser.h>
#include <Poco/Timespan.h>

#include <Poco/Logger.h>

#include <Poco/NumberParser.h>
#include <Poco/NumberFormatter.h>

#include <Poco/Util/Application.h>

#include <gumbo.h>

#include <iostream>
#include <fstream>
#include <sstream>
#include <memory>
#include <algorithm>

EventHistoryScraper::EventHistoryScraper()
	: Scraper()
{
}

VIRTUAL EventHistoryScraper::~EventHistoryScraper()
{
}

/** \brief Get result of a specified number
 *
 * \param eventName const std::string&
 * \return void
 *
 */
bool EventHistoryScraper::execute(const Event& event)
{
	bool result = false;
	try
	{
		_html = "";
		_tidyHtml = "";
		_event = event;
		_eventResults.clear();

		result = getPage();
		if(result)
		{
			if(!_tidyHtml.empty())
			{
				result = parsePage(_tidyHtml);
			}
			else if(!_html.empty())
			{
				result = parsePage(_html);
			}
		}
	}
	catch (Poco::Exception& e)
	{
		poco_error_f2(Poco::Logger::root(), "ParkRun Event History scraper for %s had error %s", _event.name, e.displayText());
	}

	return result;
}

bool EventHistoryScraper::execute(const Event& event, const std::string& html)
{
	bool result = false;

	_html = "";
	_tidyHtml = "";
	_event = event;
	_eventResults.clear();

	result = parsePage(html);

	return result;
}

Event& EventHistoryScraper::getEvent()
{
	return _event;
}

EventResults& EventHistoryScraper::getEventResults()
{
	return _eventResults;
}

bool EventHistoryScraper::getPage()
{
	return getPageHTTPrequest("https://www.parkrun.org.uk/" + _event.name + "/results/eventhistory/");
}

bool EventHistoryScraper::parsePage(const std::string& html)
{
	GumboOutput* output = gumbo_parse(html.c_str());

	GumboNode* pContentNode = parsePageFindContent(output->root);

	if(pContentNode != NULL)
	{
		GumboNode* pResultsTableNode = parsePageFindTable(pContentNode);

		parseResultsTable(pResultsTableNode);
	}

	gumbo_destroy_output(&kGumboDefaultOptions, output);

	return true;
}

GumboNode* EventHistoryScraper::parsePageFindContent(const GumboNode* pRootNode)
{
	poco_assert_dbg(pRootNode->type == GUMBO_NODE_ELEMENT);
	poco_assert_dbg(pRootNode->v.element.children.length >= 2);

	// Find <body>
	GumboNode* pBodyNode = findChildNodeByTag(pRootNode, GUMBO_TAG_BODY);
	if (pBodyNode == NULL)
	{
		return NULL;
	}

	// Find <div id="page"
	GumboNode* pDivPageNode = findChildNodeByTagAndId(pBodyNode, GUMBO_TAG_DIV, "page");
	if (pDivPageNode == NULL)
	{
		return NULL;
	}

	// Find <div id="main"
	GumboNode* pDivMainNode = findChildNodeByTagAndId(pDivPageNode, GUMBO_TAG_DIV, "main");
	if (pDivMainNode == NULL)
	{
		return NULL;
	}

	// Find <div id="primary"
	GumboNode* pDivPrimaryNode = findChildNodeByTagAndId(pDivMainNode, GUMBO_TAG_DIV, "primary");
	if (pDivPrimaryNode == NULL)
	{
		return NULL;
	}
	if(_traceHTML)
	{
		printAttributes(pDivPrimaryNode);
	}

	// Find <div id="content"
	GumboNode* pDivContentNode = findChildNodeByTagAndId(pDivPrimaryNode, GUMBO_TAG_DIV, "content");
	if (pDivContentNode == NULL)
	{
		return NULL;
	}
	if(_traceHTML)
	{
		printAttributes(pDivContentNode);
	}

	return pDivContentNode;
}

GumboNode* EventHistoryScraper::parsePageFindTable(const GumboNode* pContentNode)
{
	poco_assert_dbg(pContentNode->type == GUMBO_NODE_ELEMENT);
	poco_assert_dbg(pContentNode->v.element.children.length >= 2);

	// Find <table id="results"
	GumboNode* pTableNode = findChildNodeByTagAndId(pContentNode, GUMBO_TAG_TABLE, "results");
	if (pTableNode == NULL)
	{
		return false;
	}

	if(_traceHTML)
	{
		printAttributes(pTableNode);
	}

	return pTableNode;
}

bool EventHistoryScraper::parseResultsTable(const GumboNode* pTableNode)
{
	poco_assert_dbg(pTableNode->type == GUMBO_NODE_ELEMENT);
	poco_assert_dbg(pTableNode->v.element.children.length >= 1);

	bool result = false;

	// Find <tbody>
	GumboNode* tableBodyNode = findChildNodeByTag(pTableNode, GUMBO_TAG_TBODY);
	if (tableBodyNode == NULL)
	{
		return false;
	}

	unsigned int resultsFound = 0;

	const GumboVector* pTBodyChildren = &tableBodyNode->v.element.children;
	for (unsigned int i = 0; i < pTBodyChildren ->length; ++i)
	{
		GumboNode* child = static_cast<GumboNode*>(pTBodyChildren->data[i]);

		if (child->type == GUMBO_NODE_ELEMENT)
		{
			if(_traceHTML)
			{
				printAttributes(child);
			}

			if(child->v.element.tag == GUMBO_TAG_TR)
			{
				// Found a table row
				GumboNode* tableRow = child;

				int resultNumber = 0;
				std::string resultNumberStr;
				Poco::DateTime resultDate;
				std::string resultDateStr;

				resultsFound++;

				// Loop through Table Data in this row
				int tdCount = 0;
				const GumboVector* trChildren = &tableRow->v.element.children;
				for (unsigned int i = 0; i < trChildren ->length; ++i)
				{
					GumboNode* child = static_cast<GumboNode*>(trChildren->data[i]);

					if (child->type == GUMBO_NODE_ELEMENT)
					{
						if(_traceHTML)
						{
							printAttributes(child);
						}

						if(child->v.element.tag == GUMBO_TAG_TD)
						{
							// Found a table data TD
							GumboNode* pTableDataNode = child;
							tdCount++;

							switch (tdCount)
							{
							case 1:
								parseTableDataResultNumber(pTableDataNode, resultNumberStr);
								resultNumber = Poco::NumberParser::parse(resultNumberStr);
								break;
							case 2:
								parseTableDataDate(pTableDataNode, resultDateStr, resultDate);
								break;
							default:
								break;
							}

						}
					}
				} // Loop TDs
				if(resultNumber > 0
					&& !resultNumberStr.empty()
					&& !resultDateStr.empty())
				{
					if (_debugHTML)
					{
						poco_information(Poco::Logger::root(),
										 _event.name + " ResultNumber [" + resultNumberStr
										 + "], Date [" + resultDateStr + " (" + Poco::DateTimeFormatter::format(resultDate, "%Y-%m-%d") + ")]");
					}
					EventResult* pEventResult = new EventResult(0, resultNumber, _event.ID, resultDate, Poco::NULL_GENERIC);
					_eventResults.push_back(pEventResult);
				}
				else
				{
					poco_trace(Poco::Logger::root(),
									 "Failed scraping for data with ResultNumber [" + resultNumberStr
										 + "], Date [" + resultDateStr + " (" + Poco::DateTimeFormatter::format(resultDate, "%Y-%m-%d") + ")]");
				}
			}
		}
	} // loop TRs

	if(resultsFound != _eventResults.size())
	{
		poco_warning_f3(Poco::Logger::root(), "%s event has %u results but only %lu found to be valid.", _event.name, resultsFound, (unsigned long)_eventResults.size());
	}

	return result;
}

bool EventHistoryScraper::parseTableDataResultNumber(const GumboNode* pTableDataNode, std::string& resultNumberStr)
{
	GumboNode* aHrefNode = findChildNodeByTag(pTableDataNode, GUMBO_TAG_A);
	if (aHrefNode == NULL)
	{
		return false;
	}

	const char* aHrefTextStr = getNodeText(aHrefNode);
	if(aHrefTextStr != NULL)
	{
		resultNumberStr = aHrefTextStr;

		return true;
	}

	return false;
}

bool EventHistoryScraper::parseTableDataDate(const GumboNode* pTableDataNode, std::string& resultDateStr, Poco::DateTime& resultDate)
{
	GumboNode* aHrefNode = findChildNodeByTag(pTableDataNode, GUMBO_TAG_A);
	if (aHrefNode == NULL)
	{
		return false;
	}

	const char* aHrefTextStr = getNodeText(aHrefNode);
	if(aHrefTextStr != NULL)
	{
		resultDateStr = aHrefTextStr;

		int timezoneDifferential = 0;
		Poco::DateTimeParser::tryParse("%d/%m/%Y", resultDateStr, resultDate, timezoneDifferential);

		return true;
	}

	return false;
}
