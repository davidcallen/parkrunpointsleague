#include "EventLeagueItem.h"

EventLeagueItem::EventLeagueItem()
	: ID(0), eventLeagueID(0), position(0), genderPosition(0),
	athleteID(0), points(0), runCount(0)
{

}

EventLeagueItem::EventLeagueItem(const unsigned long _ID, const unsigned long _eventLeagueID,
								const unsigned long _athleteID, const std::string& _gender,
								const unsigned long _points, const unsigned long _runCount)
	: ID(_ID), eventLeagueID(_eventLeagueID), position(0), genderPosition(0),
	athleteID(_athleteID), gender(_gender), points(_points), runCount(_runCount)
{

}

STATIC unsigned long EventLeagueItem::calculatePoints(const unsigned long genderPosition, const unsigned long maxPoints)
{
    unsigned long points = 0;
    if(genderPosition < maxPoints)
    {
        points = maxPoints - genderPosition + 1;
        if(points < 0)
        {
            points = 0;
        }
    }
    return points;
}
