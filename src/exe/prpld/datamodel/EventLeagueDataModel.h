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
