#ifndef EventLeague_INCLUDED
#define EventLeague_INCLUDED

#include <Poco/DateTime.h>
#include <Poco/Nullable.h>

#include "../Common.h"

#include <vector>
#include <map>

class EventLeague
{
public:
	EventLeague();
	EventLeague(unsigned long _ID, unsigned long _eventID, unsigned long  _year, unsigned long latestEventResultID);

public:
    unsigned long ID;
	unsigned long eventID;
	unsigned long year;
	unsigned long latestEventResultID;
};

typedef std::vector<EventLeague*> EventLeagues;
typedef std::map<const unsigned long, EventLeague*> EventLeaguesMapByAthlete;

#endif // EventLeague_INCLUDED
