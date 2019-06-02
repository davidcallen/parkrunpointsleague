/* 
Park Run Points League website

Copyright (C) 2017  David C Allen

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/
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
	Poco::StringTokenizer stringTokenizer(name, " \n");
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
