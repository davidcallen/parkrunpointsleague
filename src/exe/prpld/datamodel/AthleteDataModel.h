#ifndef AthleteDataModel_INCLUDED
#define AthleteDataModel_INCLUDED

#include <Poco/DateTime.h>
#include <Poco/Data/Session.h>

#include "../Common.h"
#include "../dataobject/Athlete.h"

#include <utility>

class AthleteDataModel
{
public:
	static bool fetch(const unsigned long id, Athlete& athlete);
    static bool fetch(Poco::Data::Session& dbSession, const unsigned long id, Athlete& athlete);

    static bool fetch(Athletes& athletes);
    static bool fetch(Poco::Data::Session& dbSession, Athletes& athletes);

    static bool fetch(AthletesMap& athletes);
    static bool fetch(Poco::Data::Session& dbSession, AthletesMap& athletes);

    static bool insert(const Athletes& athletes);
    static bool insert(Poco::Data::Session& dbSession, const Athletes& athletes);
    static bool insert(Poco::Data::Session& dbSession, const Athlete& athlete);

    static bool update(Poco::Data::Session& dbSession, const Athlete& athlete);

    static bool reconcile(const Athletes& athletes);
    static bool reconcile(Poco::Data::Session& dbSession, const Athletes& athletes);

    static void free(Athletes& athletes);
    static void free(AthletesMap& athletes);
    static void freeAthlete(Athlete* pAthlete);
    static void freeAthletePair(std::pair<const unsigned long, Athlete*>& athletePair);
};

#endif // AthleteDataModel_INCLUDED
