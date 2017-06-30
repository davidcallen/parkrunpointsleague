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
