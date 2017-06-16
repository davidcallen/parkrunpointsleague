#include "Athlete.h"

#include <Poco/StringTokenizer.h>

STATIC const std::string Athlete::NAME_UNKNOWN("Unknown");
STATIC const std::string Athlete::GENDER_CHAR_MALE("M");
STATIC const std::string Athlete::GENDER_CHAR_FEMALE("F");

Athlete::Athlete()
	: ID(0)
{
}

Athlete::Athlete(const unsigned long id, const std::string& name, const std::string& _gender)
	: ID(id), gender(_gender)
{
    getNames(name, first_name, last_name);
    //parseGender(_gender);
}

Athlete::Athlete(const unsigned long id, const std::string& firstName, const std::string& lastName, const std::string& _gender)
	: ID(id), first_name(firstName), last_name(lastName), gender(_gender)
{
    // parseGender(_gender);
}

/*
std::string Athlete::getGenderString() const
{
    if(gender == GENDER_MALE)
    {
        return GENDER_CHAR_MALE;
    }
    else if(gender == GENDER_FEMALE)
    {
        return GENDER_CHAR_FEMALE;
    }
    else
    {
        return "";
    }
}
*/
STATIC void Athlete::getNames(const std::string& name, std::string& firstnames, std::string& lastname)
{
    Poco::StringTokenizer stringTokenizer(name, " ");
    if(stringTokenizer.count() == 2)
    {
        firstnames = stringTokenizer[0];
        lastname = stringTokenizer[1];
    }
    else if(stringTokenizer.count() > 2)
    {
        firstnames = stringTokenizer[0] + " " + stringTokenizer[1];
        lastname = stringTokenizer[2];
        if(stringTokenizer.count() > 3)
        {
            lastname += " " + stringTokenizer[3];
        }
    }
}

STATIC bool Athlete::compare(Athlete* pAthlete1, Athlete* pAthlete2)
{
    if(pAthlete1->ID != pAthlete2->ID) { return false; }
    if(pAthlete1->first_name != pAthlete2->first_name) { return false; }
    if(pAthlete1->last_name != pAthlete2->last_name) { return false; }

    return true;
}
/*
STATIC AthleteGenderEnum Athlete::parseGender(const std::string& gender)
{
    if(gender == "M")
    {
        return GENDER_MALE;
    }
    else if(gender == "F")
    {
        return GENDER_FEMALE;
    }
    else
    {
        return GENDER_UNKNOWN;
    }
}
*/
