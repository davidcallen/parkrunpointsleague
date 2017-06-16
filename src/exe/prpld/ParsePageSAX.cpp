#include "CurrentTimeHandler.h"

#include <Poco/File.h>

#include <Poco/DateTime.h>
#include <Poco/DateTimeFormatter.h>
#include <Poco/DateTimeFormat.h>

#include <Poco/Logger.h>

#include <Poco/URI.h>
#include <Poco/Net/HTTPClientSession.h>

#include <Poco/StreamCopier.h>
#include <Poco/NullStream.h>
#include <Poco/XML/ParserEngine.h>
#include <Poco/DOM/DOMParser.h>
#include <Poco/DOM/Document.h>
#include <Poco/DOM/AutoPtr.h>
#include <Poco/DOM/NodeIterator.h>
#include <Poco/DOM/NodeFilter.h>
#include <Poco/DOM/Node.h>
#include <Poco/DOM/NodeList.h>
#include <Poco/DOM/NamedNodeMap.h>

#include <Poco/Util/Application.h>


#include <iostream>
#include <fstream>
#include <sstream>
#include <memory>



bool CurrentTimeHandler::parsePageSAX(const std::string& html)
{
	try
	{
		Poco::XML::DOMParser parser;
		parser.setFeature(Poco::XML::DOMParser::FEATURE_FILTER_WHITESPACE, false);

		Poco::XML::AutoPtr<Poco::XML::Document> pDoc = parser.parseString(html);

		poco_information(Poco::Logger::root(), "Latest results page parsed into DOM");

		Poco::XML::NodeIterator itr(pDoc, Poco::XML::NodeFilter::SHOW_ALL);
		Poco::XML::Node* pNode = itr.nextNode();
		while(pNode)
		{
			std::string leading;
			Poco::XML::Node* pParentNode = pNode->parentNode();
			while(0 != pParentNode)
			{
				pParentNode = pParentNode->parentNode();
				leading += " ";
			}

			// msg.Message(leading + pNode->nodeName() + ":" + pNode->nodeValue());
			poco_information(Poco::Logger::root(), "Latest results page : " + leading + pNode->nodeName() + ":" + pNode->nodeValue());

			if(pNode->hasAttributes())
			{
				for(unsigned long i = 0; i < pNode->attributes()->length(); ++i)
				{
					poco_information(Poco::Logger::root(), leading + " " +
							pNode->attributes()->item(i)->nodeName() +
							"=\"" +
							pNode->attributes()->item(i)->nodeValue() +
							"\"");
				}
			}
			pNode = itr.nextNode();
		}
	}
	catch(Poco::Exception& exc)
	{
		poco_information(Poco::Logger::root(), "Latest results page parsing failed with " + exc.displayText());
		return false;
	}

	return true;
}

