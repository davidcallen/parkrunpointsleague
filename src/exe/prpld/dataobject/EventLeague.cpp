#include "EventLeague.h"

EventLeague::EventLeague()
	: ID(0), eventID(0), year(0), latestEventResultID(0)
{
}

EventLeague::EventLeague(unsigned long _ID, unsigned long _eventID, unsigned long _year, unsigned long _latestEventResultID)
	: ID(_ID), eventID(_eventID), year(_year), latestEventResultID(_latestEventResultID)
{
}
