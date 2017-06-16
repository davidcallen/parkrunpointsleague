#ifndef EventDataModel_INCLUDED
#define EventDataModel_INCLUDED

#include <Poco/DateTime.h>
#include <Poco/Data/Session.h>

#include "../Common.h"
#include "../dataobject/Event.h"

class EventDataModel
{
public:
	static bool fetch(const std::string& name, Event& event);
	static bool fetch(Poco::Data::Session& dbSession, const std::string& name, Event& event);

    static bool fetch(Events& events);
    static bool fetch(Poco::Data::Session& dbSession, Events& events);


    static bool update(const Event& event);
    static bool update(Poco::Data::Session& dbSession, const Event& event);

    static void free(Events& events);
    static void freeEvent(Event* pEvent);
};

#endif // EventDataModel_INCLUDED
