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
