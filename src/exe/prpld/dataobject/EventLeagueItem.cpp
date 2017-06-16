#include "EventLeagueItem.h"

EventLeagueItem::EventLeagueItem()
	: ID(0), eventLeagueID(0), position(0),
	athleteID(0), points(0), runCount(0)
{

}

EventLeagueItem::EventLeagueItem(unsigned long _ID, unsigned long _eventLeagueID,
								unsigned long _athleteID, unsigned long _points, unsigned long _runCount)
	: ID(_ID), eventLeagueID(_eventLeagueID), position(0),
	athleteID(_athleteID), points(_points), runCount(_runCount)
{

}
