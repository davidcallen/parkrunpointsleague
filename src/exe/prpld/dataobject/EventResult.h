#ifndef EventResult_INCLUDED
#define EventResult_INCLUDED

#include <Poco/DateTime.h>
#include <Poco/Nullable.h>

#include "../Common.h"

#include <vector>

class EventResult
{
public:
    EventResult();
	EventResult(const unsigned long _ID, const unsigned long _resultNumber, const unsigned long _eventID,
                const Poco::DateTime _date, const Poco::Nullable<unsigned long> _leagueYear);

public:
    unsigned long ID;
    unsigned long resultNumber;
    unsigned long eventID;
    Poco::DateTime date;
    Poco::Nullable<unsigned long> leagueYear;
};

typedef std::vector<EventResult*> EventResults;

#endif // EventResult_INCLUDED
