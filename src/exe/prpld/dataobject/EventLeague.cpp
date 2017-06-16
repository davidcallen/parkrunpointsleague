#include "EventLeague.h"

EventLeague::EventLeague()
	: ID(0), eventID(0), year(0)
{
}

EventLeague::EventLeague(unsigned long _ID, unsigned long _eventID, unsigned long _year)
	: ID(_ID), eventID(_eventID), year(_year)
{
}
