#include "ResultsScraper.h"

#include "datamodel/EventResultItemDataModel.h"

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

ResultsScraper::ResultsScraper()
	: Scraper()
{
}

VIRTUAL ResultsScraper::~ResultsScraper()
{
}

/** \brief Get result of a specified number
 *
 * \param name const std::string&
 * \param resultNumber const unsignedlong
 * \return void
 *
 */
bool ResultsScraper::execute(const Event& event, const EventResult& eventResult)
{
	bool result = false;

	try
	{
		_html = "";
		_tidyHtml = "";
		_event = event;
		_eventResult = eventResult;

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
		poco_error_f2(Poco::Logger::root(), "ParkRun results scraper for %s had error %s", event.name, e.displayText());
	}

	return result;
}

bool ResultsScraper::execute(const Event& event, const EventResult& eventResult, const std::string& html)
{
	_html = "";
	_tidyHtml = "";
	_event = event;
	_eventResult = eventResult;

	return parsePage(html);
}

Event ResultsScraper::getEvent()
{
	return _event;
}

EventResult ResultsScraper::getEventResult()
{
	return _eventResult;
}

EventResultItems ResultsScraper::getEventResultItems()
{
	return _eventResultItems;
}

Athletes ResultsScraper::getAthletes()
{
	return _athletes;
}

bool ResultsScraper::getPage()
{
	bool result = false;

	std::string url;
	if(_eventResult.resultNumber == 0)
	{
		url = "http://www.parkrun.org.uk/" + _event.name + "/results/latestresults/";
	}
	else
	{
		url = "http://www.parkrun.org.uk/" + _event.name + "/results/weeklyresults/?runSeqNumber=" + Poco::NumberFormatter::format(_eventResult.resultNumber);
	}
	result = getPageHTTPrequest(url);

	return result;
}

bool ResultsScraper::parsePage(const std::string& html)
{
	GumboOutput* pOutput = gumbo_parse(html.c_str());

	GumboNode* pContentNode = parsePageFindContent(pOutput->root);

	if(pContentNode != NULL)
	{
		parseContentNode(pContentNode);

		GumboNode* pResultsTableNode = parsePageFindTable(pContentNode);
		if(pResultsTableNode == NULL)
		{
			return false;
		}

		parseResultsTable(pResultsTableNode);
	}

	gumbo_destroy_output(&kGumboDefaultOptions, pOutput);

	return true;
}

GumboNode* ResultsScraper::parsePageFindContent(const GumboNode* pRootNode)
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

GumboNode* ResultsScraper::parsePageFindTable(const GumboNode* pContentNode)
{
	poco_assert_dbg(pContentNode->type == GUMBO_NODE_ELEMENT);
	poco_assert_dbg(pContentNode->v.element.children.length >= 2);

	// Find <table id="results"
	GumboNode* pTableNode = findChildNodeByTagAndId(pContentNode, GUMBO_TAG_TABLE, "results");
	if (pTableNode == NULL)
	{
		return NULL;
	}
	if(_traceHTML)
	{
		printAttributes(pTableNode);
	}

	return pTableNode;
}


bool ResultsScraper::parseContentNode(const GumboNode* pContentNode)
{
	poco_assert_dbg(pContentNode->type == GUMBO_NODE_ELEMENT);
	poco_assert_dbg(pContentNode->v.element.children.length >= 1);

	bool result = false;

	// Find <h2>
	GumboNode* pTitleNode = findChildNodeByTag(pContentNode, GUMBO_TAG_H2);
	if (pTitleNode == NULL)
	{
		return false;
	}

	result = parseContentDataTitle(pTitleNode);

	return result;
}

bool ResultsScraper::parseContentDataTitle(const GumboNode* pTitleDataNode)
{
	_eventResult.eventID = _event.ID;

	const char* titleTextChar = getNodeText(pTitleDataNode);
	if(titleTextChar != NULL)
	{
		std::string titleTextStr = titleTextChar;

		std::string eventNumberStr;
		std::string eventDateStr;
		int timezoneDifferential = 0;

		size_t hashDelimiterPos = titleTextStr.find("#");
		if(hashDelimiterPos != std::string::npos)
		{
			size_t hyphenDelimiterPos = titleTextStr.find("-");
			if(hyphenDelimiterPos != std::string::npos)
			{
				eventNumberStr = Poco::trim(titleTextStr.substr(hashDelimiterPos + 1, hyphenDelimiterPos - hashDelimiterPos - 1));
				eventDateStr = Poco::trim(titleTextStr.substr(hyphenDelimiterPos + 1));

				unsigned int eventNumber = 0;
				if(Poco::NumberParser::tryParseUnsigned(eventNumberStr, eventNumber))
				{
					_eventResult.resultNumber = eventNumber;
				}
				Poco::DateTimeParser::tryParse("%d/%m/%Y", eventDateStr, _eventResult.date, timezoneDifferential);
			}
		}

		if (_debugHTML)
		{
			poco_information(Poco::Logger::root(),
							 "Event [" + eventNumberStr
							 + "] on [" + Poco::DateTimeFormatter::format(_eventResult.date, "%Y-%m-%d", timezoneDifferential) + "]");
		}

		return true;
	}

	return false;
}

bool ResultsScraper::parseResultsTable(const GumboNode* pTableNode)
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

	unsigned int resultItemsFound = 0;

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

				int position = 0;
				std::string positionStr;
				Poco::Nullable<unsigned long> genderPosition = Poco::NULL_GENERIC;
				std::string genderPositionStr;
				std::string athleteName;
				std::string athleteNumberStr;
				int athleteNumber = 0;
				std::string durationStr;
				Poco::Timespan durationTimespan;
				std::string genderStr;

				resultItemsFound++;

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
								parseTableDataPosition(pTableDataNode, positionStr);
								position = Poco::NumberParser::parse(positionStr);
								break;
							case 2:
								parseTableDataAthlete(pTableDataNode, athleteNumberStr, athleteName);
								if(!athleteNumberStr.empty())
								{
									athleteNumber = Poco::NumberParser::parse(athleteNumberStr);
								}
								break;
							case 3:
								parseTableDataDuration(pTableDataNode, durationStr);
								timespanParse(durationStr, durationTimespan);
								break;
							case 6:
								parseTableDataGender(pTableDataNode, genderStr);
								break;
							case 7:
								parseTableDataGenderPosition(pTableDataNode, genderPositionStr);
								if(!genderPositionStr.empty())
                                {
                                    genderPosition = Poco::NumberParser::parse(genderPositionStr);
                                }
								break;
							default:
								break;
							}

						}
					}
				} /* Loop TDs */
				if(position > 0
						&& !positionStr.empty()
						&& (
							(!athleteNumberStr.empty() && athleteNumber > 0 && !athleteName.empty() && !durationStr.empty())
							|| (athleteName == Athlete::NAME_UNKNOWN)
						) )
			{
				if (_debugHTML)
					{
						poco_information(Poco::Logger::root(),
										 "Position [" + positionStr
										 + "], Athlete [" + athleteNumberStr + " " + athleteName
										 + "], Duration [" + durationStr + " (" + Poco::DateTimeFormatter::format(durationTimespan, "%h:%M:%S")
										 + " secs " + Poco::NumberFormatter::format(durationTimespan.totalSeconds()) + "]");
					}

                    EventResultItem* pEventResultItem = NULL;
                    if(athleteName == Athlete::NAME_UNKNOWN)
                    {
                        pEventResultItem = new EventResultItem(0, _eventResult.eventID, position, genderPosition,
                                                                                Poco::NULL_GENERIC, Poco::NULL_GENERIC);
                    }
                    else
                    {
                        pEventResultItem = new EventResultItem(0, _eventResult.eventID, position, genderPosition,
                                                                                athleteNumber, durationTimespan.totalSeconds());
                        Athlete* pAthlete = new Athlete(athleteNumber, athleteName, genderStr);
                        _athletes.push_back(pAthlete);
                    }
					_eventResultItems.push_back(pEventResultItem);
				}
				else
				{
					poco_error(Poco::Logger::root(),
							   "Failed to parse all data with Position [" + positionStr
							   + "], Athlete [" + athleteNumberStr + " " + athleteName
							   + "], Duration [" + durationStr + " (" + Poco::DateTimeFormatter::format(durationTimespan, "%h:%M:%S")
							   + " secs " + Poco::NumberFormatter::format(durationTimespan.totalSeconds()) + "]");
				}
			}
		}
	} /* loop TRs */

	if(resultItemsFound != _eventResultItems.size())
	{
		poco_warning_f3(Poco::Logger::root(), "%s event has %u results but only %hu found to be valid.",
                        _event.name, resultItemsFound, (unsigned long)_eventResultItems.size());
	}

	return result;
}

bool ResultsScraper::parseTableDataPosition(const GumboNode* pTableDataNode, std::string& positionStr)
{
	const char* tdTextStr = getNodeText(pTableDataNode);
	if(tdTextStr != NULL)
	{
		positionStr = tdTextStr;

		return true;
	}

	return false;
}

bool ResultsScraper::parseTableDataAthlete(const GumboNode* pTableDataNode, std::string& athleteNumberStr, std::string& athleteName)
{
	const GumboVector* tdChildren = &pTableDataNode->v.element.children;

	if(tdChildren->length == 1)
	{
		const char* tdTextStr = getNodeText(pTableDataNode);
		if(tdTextStr != NULL)
		{
			athleteName = tdTextStr;

			return true;
		}
	}

	for (unsigned int i = 0; i < tdChildren->length; ++i)
	{
		GumboNode* child = static_cast<GumboNode*>(tdChildren->data[i]);

		if (child->type == GUMBO_NODE_ELEMENT)
		{
			if(_traceHTML)
			{
				printAttributes(child);
			}

			if(child->v.element.tag == GUMBO_TAG_A)
			{
				// Found a table data TD
				GumboNode* aNode = child;

				const char* tdTextStr = getNodeText(aNode);
				if(tdTextStr != NULL)
				{
					athleteName = tdTextStr;
				}

				GumboAttribute* idAttr = gumbo_get_attribute(&child->v.element.attributes, "href");
				if (idAttr != NULL)
				{
					// TODO : parse this href to get athlete number
					std::string attrValue = idAttr->value;

					size_t equalsDelimiterPos = attrValue.rfind("=");
					if (equalsDelimiterPos != std::string::npos)
					{
						athleteNumberStr = attrValue.substr(equalsDelimiterPos + 1);

						return true;
					}

				}
			}
			else if (child->type == GUMBO_NODE_TEXT)
			{
				GumboText textNode = child->v.text;
				athleteName = textNode.text;

				return true;
			}
		}
	}

	return false;
}

bool ResultsScraper::parseTableDataDuration(const GumboNode* pTableDataNode, std::string& durationStr)
{
	const char* tdTextStr = getNodeText(pTableDataNode);
	if(tdTextStr != NULL)
	{
		durationStr = tdTextStr;

		return true;
	}

	return false;
}

bool ResultsScraper::parseTableDataGender(const GumboNode* pTableDataNode, std::string& genderStr)
{
	const char* tdTextStr = getNodeText(pTableDataNode);
	if(tdTextStr != NULL)
	{
		genderStr = tdTextStr;

		return true;
	}

	return false;
}

bool ResultsScraper::parseTableDataGenderPosition(const GumboNode* pTableDataNode, std::string& genderPositionStr)
{
	const char* tdTextStr = getNodeText(pTableDataNode);
	if(tdTextStr != NULL)
	{
		genderPositionStr = tdTextStr;

		return true;
	}

	return false;
}

