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

    static bool fetch(const unsigned long eventID, const unsigned long resultNumber, EventResult& eventResult);
    static bool fetch(Poco::Data::Session& dbSession, const unsigned long eventID, const unsigned long resultNumber, EventResult& eventResult);

    static bool fetch(const unsigned long eventID, EventResults& eventResults);
    static bool fetch(Poco::Data::Session& dbSession, const unsigned long eventID, EventResults& eventResults);

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
