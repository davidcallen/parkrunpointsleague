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
#ifndef EventResultDataModel_INCLUDED
#define EventResultDataModel_INCLUDED

#include <Poco/DateTime.h>
#include <Poco/Data/Session.h>

#include "../Common.h"
#include "../dataobject/EventResult.h"

class EventResultDataModel
{
public:
    static void getLastResultDate(Poco::DateTime& date);

    static bool fetch(const unsigned long eventID, const Poco::DateTime& date, EventResults& eventResults);
    static bool fetch(Poco::Data::Session& dbSession, const unsigned long eventID, const Poco::DateTime& date, EventResults& eventResults);

    static bool fetch(const unsigned long eventID, const unsigned long leagueYear, EventResults& eventResults);
    static bool fetch(Poco::Data::Session& dbSession, const unsigned long eventID, const unsigned long leagueYear, EventResults& eventResults);

    static bool fetch(const unsigned long eventID, EventResults& eventResults);
    static bool fetch(Poco::Data::Session& dbSession, const unsigned long eventID, EventResults& eventResults);

    static bool fetch(const unsigned long eventResultID, EventResult& eventResult);
    static bool fetch(Poco::Data::Session& dbSession, const unsigned long eventResultID, EventResult& eventResult);

    static bool fetch(const unsigned long eventID, const unsigned long resultNumber, EventResult& eventResult);
    static bool fetch(Poco::Data::Session& dbSession, const unsigned long eventID, const unsigned long resultNumber, EventResult& eventResult);

    static bool update(const EventResult& eventResult);
    static bool update(Poco::Data::Session& dbSession, const EventResult& eventResult);

    static bool insert(const EventResult& eventResult);
    static bool insert(Poco::Data::Session& dbSession, const EventResult& eventResult);

    static bool remove(const EventResult* pEventResult);
    static bool remove(Poco::Data::Session& dbSession, const EventResult* pEventResult);

    static bool remove(const unsigned long eventResultNumber);
    static bool remove(Poco::Data::Session& dbSession, const unsigned long eventResultNumber);

    static void free(EventResults& eventResults);
    static void freeEventResult(EventResult* pEventResult);

};

#endif // EventResultDataModel_INCLUDED
