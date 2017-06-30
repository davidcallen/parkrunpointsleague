#ifndef EventLeagueItem_INCLUDED
#define EventLeagueItem_INCLUDED

#include <Poco/DateTime.h>
#include <Poco/Nullable.h>

#include "../Common.h"

#include <vector>
#include <map>

class EventLeagueItem
{
public:
	EventLeagueItem();
	EventLeagueItem(const unsigned long _ID, const unsigned long _eventLeagueID,
					const unsigned long _athleteID, const std::string& _gender,
					const unsigned long _points, const unsigned long _runCount);

public:
    unsigned long ID;
	unsigned long eventLeagueID;
	unsigned long position;
	unsigned long genderPosition;
	std::string gender;
	unsigned long athleteID;
	unsigned long points;
	unsigned long runCount;
};

typedef std::vector<EventLeagueItem*> EventLeagueItems;
typedef std::map<const unsigned long, EventLeagueItem*> EventLeagueItemsMapByAthlete;


#endif // EventLeagueItem_INCLUDED
