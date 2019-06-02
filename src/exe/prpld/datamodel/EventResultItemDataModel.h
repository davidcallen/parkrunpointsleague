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
#ifndef EventResultItemDataModel_INCLUDED
#define EventResultItemDataModel_INCLUDED

#include <Poco/DateTime.h>
#include <Poco/Data/Session.h>

#include "../Common.h"
#include "../dataobject/EventResultItem.h"


class EventResultItemDataModel
{
public:
	static bool fetch(const unsigned long eventResultID, EventResultItems& eventResultItems);
	static bool fetch(Poco::Data::Session& dbSession, const unsigned long eventResultID, EventResultItems& eventResultItems);

	static bool fetch(const unsigned long eventResultID, const unsigned long athleteID, EventResultItem& eventResultItem);
	static bool fetch(Poco::Data::Session& dbSession, const unsigned long eventResultID, const unsigned long athleteID, EventResultItem& eventResultItem);

	static unsigned long fetchCount(const unsigned long eventResultID);
	static unsigned long fetchCount(Poco::Data::Session& dbSession, const unsigned long eventResultID);

	static bool insert(EventResultItem* pEventResultItem);
	static bool insert(Poco::Data::Session& dbSession, EventResultItem* pEventResultItem);

	static bool remove(const unsigned long eventResultID);
	static bool remove(Poco::Data::Session& dbSession, const unsigned long eventResultID);


	static void free(EventResultItems& eventResultItems);
	static void freeEventResultItem(EventResultItem* pEventResultItem);
};

#endif // EventResultItemDataModel_INCLUDED
