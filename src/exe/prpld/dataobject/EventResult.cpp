#include "EventResult.h"

EventResult::EventResult()
	: ID(0), resultNumber(0), eventID(0)
{
}

EventResult::EventResult(const unsigned long _ID, const unsigned long _resultNumber, const unsigned long _eventID,
                         const Poco::DateTime _date, const Poco::Nullable<unsigned long> _leagueYear)
    : ID(_ID), resultNumber(_resultNumber), eventID(_eventID), date(_date), leagueYear(_leagueYear)
{
}
