#include "Event.h"

Event::Event()
	: ID(0), birthday(Poco::NULL_GENERIC)
{
}

Event::Event(const std::string& p_name, const std::string& p_title, const Poco::Nullable<Poco::DateTime>& p_birthday)
	: ID(0), name(p_name), title(p_title), birthday(p_birthday)
{
}

/*
VIRTUAL unsigned long Event::getBirthdayMonth()
{
    if(_birthdayMonth == 0)
    {
        splitBirthday();
    }

    return _birthdayMonth;
}

VIRTUAL unsigned long Event::getBirthdayDay()
{
    if(_birthdayDay == 0)
    {
        splitBirthday();
    }

    return _birthdayDay;
}

VIRTUAL void Event::splitBirthday()
{
    Poco::StringTokenizer tokenizer(birthday, "-");
    if(tokenizer.size() > 0)
    {
        _birthdayMonth = Poco::NumberParser(tokenizer[0]);
    }
    if(tokenizer.size() > 1)
    {
        _birthdayDay = Poco::NumberParser(tokenizer[1]);
    }
}

*/
