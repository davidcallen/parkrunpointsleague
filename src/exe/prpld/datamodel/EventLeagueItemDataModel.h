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
#ifndef EventLeagueItemDataModel_INCLUDED
#define EventLeagueItemDataModel_INCLUDED

#include <Poco/DateTime.h>
#include <Poco/Data/Session.h>

#include "../Common.h"
#include "../dataobject/EventLeagueItem.h"


class EventLeagueItemDataModel
{
public:
    static bool fetch(const unsigned long eventLeagueID, const std::string& orderByFieldName, EventLeagueItems& eventLeagues);
    static bool fetch(Poco::Data::Session& dbSession, const unsigned long eventLeagueID, const std::string& orderByFieldName, EventLeagueItems& eventLeagues);

    static bool fetch(const unsigned long eventLeagueID, const unsigned long athleteID, EventLeagueItem& eventLeague);
    static bool fetch(Poco::Data::Session& dbSession, const unsigned long eventLeagueID, const unsigned long athleteID, EventLeagueItem& eventLeague);

    static bool insert(EventLeagueItem* pEventLeagueItem);
    static bool insert(Poco::Data::Session& dbSession, EventLeagueItem* pEventLeagueItem);

    static bool remove(const unsigned long eventLeagueID);
    static bool remove(Poco::Data::Session& dbSession, const unsigned long eventLeagueID);
    static bool remove(Poco::Data::Session& dbSession, const unsigned long eventLeagueID, const unsigned long leagueYear);

    static void free(EventLeagueItems& eventLeagues);
    static void free(EventLeagueItemsMapByAthlete& eventLeaguesMapByAthlete);
    static void freeEventLeagueItem(EventLeagueItem* pEventLeagueItem);
    static void freeEventLeagueItemPair(std::pair<const unsigned long, EventLeagueItem*>& eventLeaguePair);
};

#endif // EventLeagueItemDataModel_INCLUDED
