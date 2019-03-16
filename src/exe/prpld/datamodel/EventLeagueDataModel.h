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
#ifndef EventLeagueDataModel_INCLUDED
#define EventLeagueDataModel_INCLUDED

#include <Poco/DateTime.h>
#include <Poco/Data/Session.h>

#include "../Common.h"
#include "../dataobject/EventLeague.h"


class EventLeagueDataModel
{
public:
    static bool fetch(const unsigned long eventID, EventLeagues& eventLeagues);
    static bool fetch(Poco::Data::Session& dbSession, const unsigned long eventID, EventLeagues& eventLeagues);

    static bool fetch(const unsigned long eventID, const unsigned long year, EventLeague& eventLeague);
    static bool fetch(Poco::Data::Session& dbSession, const unsigned long eventID, const unsigned long year, EventLeague& eventLeague);

    static bool update(EventLeague* pEventLeague);
    static bool update(Poco::Data::Session& dbSession, EventLeague* pEventLeague);

    static bool insert(EventLeague* pEventLeague);
    static bool insert(Poco::Data::Session& dbSession, EventLeague* pEventLeague);

    static bool remove(const unsigned long eventID);
    static bool remove(Poco::Data::Session& dbSession, const unsigned long eventID);
    static bool remove(Poco::Data::Session& dbSession, const unsigned long eventID, const unsigned long leagueYear);

    static void free(EventLeagues& eventLeagues);
    static void freeEventLeague(EventLeague* pEventLeague);
    static void freeEventLeaguePair(std::pair<const unsigned long, EventLeague*>& eventLeaguePair);
};

#endif // EventLeagueDataModel_INCLUDED
