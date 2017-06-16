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
