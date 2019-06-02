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
#ifndef Athlete_INCLUDED
#define Athlete_INCLUDED

#include "../Common.h"

#include <vector>
#include <map>

/*
enum AthleteGenderEnum
{
	GENDER_UNKNOWN=0,
	GENDER_MALE=1,
	GENDER_FEMALE=2
};
*/
class Athlete
{
public:
	static const std::string NAME_UNKNOWN;
	static const std::string GENDER_CHAR_MALE;
	static const std::string GENDER_CHAR_FEMALE;

public:
	Athlete();
	Athlete(const unsigned long id, const std::string& firstName, const std::string& lastName, const std::string& gender);
	Athlete(const unsigned long id, const std::string& name, const std::string& gender);

	// std::string getGenderString() const;

public:
	static void getNames(const std::string& name, std::string& firstnames, std::string& lastname);
	// static AthleteGenderEnum parseGender(const std::string& gender);
	static bool compare(Athlete* pAthlete1, Athlete* pAthlete2);

public:
	unsigned long ID;
	std::string first_name;
	std::string last_name;
	// AthleteGenderEnum gender;
	std::string gender;
};

typedef std::vector<Athlete*> Athletes;
typedef std::map<const unsigned long, Athlete*> AthletesMap;

#endif // Athlete_INCLUDED
