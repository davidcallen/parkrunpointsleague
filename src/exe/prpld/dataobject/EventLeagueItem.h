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
	EventLeagueItem(unsigned long _ID, unsigned long _eventLeagueID,
					unsigned long _athleteID, unsigned long _points, unsigned long _runCount);

public:
    unsigned long ID;
	unsigned long eventLeagueID;
	unsigned long position;
	unsigned long athleteID;
	unsigned long points;
	unsigned long runCount;
};

typedef std::vector<EventLeagueItem*> EventLeagueItems;
typedef std::map<const unsigned long, EventLeagueItem*> EventLeagueItemsMapByAthlete;

/*
struct CompareByRunPoints : public std::binary_function <bool, std::string, std::string>
{
  bool operator() (const EventLeagueItem& lhs, const std::string& rhs)
  {
    // return true if lhs < rhs
    // return false otherwise

    // step 1:  compare years.  if lhs.year < rhs.year, return true.  else, continue
    // step 2: compare months.  if lhs.month < rhs.month, return true.  else, continue.
    //    note:  don't just compare the strings, else "AUG" < "JAN" etc
    // step 3: compare days.  if lhs.day < rhs.day, return true.  else, return false.
  }
};
typedef std::map<const unsigned long, EventLeagueItem*, CompareByRunPoints> EventLeagueItemsMapByAthlete;
*/

#endif // EventLeagueItem_INCLUDED
