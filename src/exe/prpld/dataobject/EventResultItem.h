#ifndef EventResultItem_INCLUDED
#define EventResultItem_INCLUDED

#include <Poco/DateTime.h>
#include <Poco/Nullable.h>

#include "../Common.h"

#include <vector>

class EventResultItem
{
public:
	EventResultItem();
	EventResultItem(const unsigned long _ID, const unsigned long eventResultID, const unsigned long position,
                    Poco::Nullable<unsigned long> genderPosition, Poco::Nullable<std::string> gender, Poco::Nullable<unsigned long> athleteID,
                    Poco::Nullable<unsigned long> durationSecs);

public:
    unsigned long ID;
	unsigned long eventResultID;
	unsigned long position;
	Poco::Nullable<unsigned long> genderPosition;
	Poco::Nullable<std::string> gender;
	Poco::Nullable<unsigned long> athleteID;
	Poco::Nullable<unsigned long> durationSecs;

public:
    Poco::Timespan getDurationTimespan() const;
};

typedef std::vector<EventResultItem*> EventResultItems;

#endif // EventResultItem_INCLUDED
