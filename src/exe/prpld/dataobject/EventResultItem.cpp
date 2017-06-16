#include "EventResultItem.h"

EventResultItem::EventResultItem()
	: ID(0), eventResultID(0), position(0), genderPosition(Poco::NULL_GENERIC),
	athleteID(Poco::NULL_GENERIC), durationSecs(Poco::NULL_GENERIC)
{

}

EventResultItem::EventResultItem(const unsigned long _ID, const unsigned long _eventResultID, const unsigned long _position,
                                 Poco::Nullable<unsigned long> _genderPosition, Poco::Nullable<unsigned long> _athleteID,
                                 Poco::Nullable<unsigned long> _durationSecs)
	: ID(_ID), eventResultID(_eventResultID), position(_position), genderPosition(_genderPosition),
	athleteID(_athleteID), durationSecs(_durationSecs)
{

}

Poco::Timespan EventResultItem::getDurationTimespan() const
{
    Poco::Timespan durationTimespan;
    if(!durationSecs.isNull())
    {
        durationTimespan.assign(0, 0, 0, durationSecs.value(), 0);
    }

    return durationTimespan;
}
