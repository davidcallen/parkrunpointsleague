#ifndef Event_INCLUDED
#define Event_INCLUDED

#include <Poco/Nullable.h>
#include <Poco/DateTime.h>

#include "../Common.h"

#include <vector>

class Event
{
public:
	Event();
	Event(const std::string& p_name, const std::string& p_title, const Poco::Nullable<Poco::DateTime>& p_birthday = Poco::NULL_GENERIC);

//	virtual unsigned long getBirthdayMonth();
//	virtual unsigned long getBirthdayDay();

public:
    unsigned long ID;
	std::string name;
	std::string title;
    Poco::Nullable<Poco::DateTime> birthday;

/*	std::string birthday;

protected:
	virtual void splitBirthday();

protected:
    unsigned long _birthdayMonth;
    unsigned long _birthdayDay;
    */
};

typedef std::vector<Event*> Events;

#endif // Event_INCLUDED
