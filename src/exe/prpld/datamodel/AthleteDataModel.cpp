#include "AthleteDataModel.h"
#include "../PRPLHTTPServerApplication.h"

#include <Poco/Util/Application.h>
#include <Poco/Data/Session.h>
#include <Poco/DateTime.h>

#include <algorithm>
#include <utility>

STATIC bool AthleteDataModel::fetch(const unsigned long id, Athlete& athlete)
{
    Poco::Data::Session dbSession = PRPLHTTPServerApplication::instance().getDbSessionPool()->get();

    return fetch(dbSession, id, athlete);
}

STATIC bool AthleteDataModel::fetch(Poco::Data::Session& dbSession, const unsigned long id, Athlete& athlete)
{
	bool result = true;

	Poco::Data::Statement select(dbSession);
	select << "select ID, FIRST_NAME, LAST_NAME from ATHLETE where ID = ?",
		Poco::Data::Keywords::into(athlete.ID),
		Poco::Data::Keywords::into(athlete.first_name),
		Poco::Data::Keywords::into(athlete.last_name),
		Poco::Data::Keywords::useRef(id),
		Poco::Data::Keywords::now;

	result = (athlete.ID != 0);

	return result;
}

STATIC bool AthleteDataModel::fetch(Athletes& athletes)
{
    Poco::Data::Session dbSession = PRPLHTTPServerApplication::instance().getDbSessionPool()->get();

    return fetch(dbSession, athletes);
}

STATIC bool AthleteDataModel::fetch(Poco::Data::Session& dbSession, Athletes& athletes)
{
    bool result = true;

    Athlete tmpAthlete;

	Poco::Data::Statement dbStmt(dbSession);
	dbStmt << "select ID, FIRST_NAME, LAST_NAME, GENDER from ATHLETE",
		   Poco::Data::Keywords::into(tmpAthlete.ID),
		   Poco::Data::Keywords::into(tmpAthlete.first_name),
		   Poco::Data::Keywords::into(tmpAthlete.last_name),
		   Poco::Data::Keywords::into(tmpAthlete.gender),
		   Poco::Data::Keywords::range(0, 1);

	while (!dbStmt.done())
	{
        if(dbStmt.execute() > 0)
        {
            Athlete* pAthlete = new Athlete;
            *pAthlete = tmpAthlete;

            athletes.push_back(pAthlete);
        }
	}

    return result;
}

STATIC bool AthleteDataModel::fetch(AthletesMap& athletes)
{
    Poco::Data::Session dbSession = PRPLHTTPServerApplication::instance().getDbSessionPool()->get();

    return fetch(dbSession, athletes);
}

STATIC bool AthleteDataModel::fetch(Poco::Data::Session& dbSession, AthletesMap& athletes)
{
    bool result = true;

    Athlete tmpAthlete;

	Poco::Data::Statement dbStmt(dbSession);
	dbStmt << "select ID, FIRST_NAME, LAST_NAME, GENDER from ATHLETE",
		   Poco::Data::Keywords::into(tmpAthlete.ID),
		   Poco::Data::Keywords::into(tmpAthlete.first_name),
		   Poco::Data::Keywords::into(tmpAthlete.last_name),
		   Poco::Data::Keywords::into(tmpAthlete.gender),
		   Poco::Data::Keywords::range(0, 1);

	while (!dbStmt.done())
	{
        if(dbStmt.execute() > 0)
        {
            Athlete* pAthlete = new Athlete;
            *pAthlete = tmpAthlete;

            athletes[pAthlete->ID] = pAthlete;
        }
	}

    return result;
}

STATIC bool AthleteDataModel::insert(const Athletes& athletes)
{
    Poco::Data::Session dbSession = PRPLHTTPServerApplication::instance().getDbSessionPool()->get();

    return insert(dbSession, athletes);
}

STATIC bool AthleteDataModel::insert(Poco::Data::Session& dbSession, const Athletes& athletes)
{
    bool result = false;

    Athletes::const_iterator iter;
    for(iter = athletes.begin(); iter != athletes.end(); ++iter)
    {
        Athlete* pAthlete = *iter;

        result = AthleteDataModel::insert(dbSession, *pAthlete);
    }

    return result;
}

STATIC bool AthleteDataModel::insert(Poco::Data::Session& dbSession, const Athlete& athlete)
{
    bool result = true;

	Poco::Data::Statement dbStmt(dbSession);
	dbStmt << "insert into ATHLETE (ID, FIRST_NAME, LAST_NAME, GENDER) values (?, ?, ?, ?)",
		   Poco::Data::Keywords::useRef(athlete.ID),
		   Poco::Data::Keywords::useRef(athlete.first_name),
		   Poco::Data::Keywords::useRef(athlete.last_name),
		   Poco::Data::Keywords::useRef(athlete.gender),
		   Poco::Data::Keywords::now;

    result = true;

    return result;
}

STATIC bool AthleteDataModel::update(Poco::Data::Session& dbSession, const Athlete& athlete)
{
    bool result = true;

	Poco::Data::Statement dbStmt(dbSession);
	dbStmt << "update ATHLETE set FIRST_NAME = ?, LAST_NAME = ?, GENDER = ? where ID = ?",
		   Poco::Data::Keywords::useRef(athlete.first_name),
		   Poco::Data::Keywords::useRef(athlete.last_name),
		   Poco::Data::Keywords::useRef(athlete.gender),
		   Poco::Data::Keywords::useRef(athlete.ID),
		   Poco::Data::Keywords::now;

    result = true;

    return result;
}

STATIC bool AthleteDataModel::reconcile(const Athletes& athletes)
{
    Poco::Data::Session dbSession = PRPLHTTPServerApplication::instance().getDbSessionPool()->get();

    return reconcile(dbSession, athletes);
}

// Note: We dont remove any Athletes
STATIC bool AthleteDataModel::reconcile(Poco::Data::Session& dbSession, const Athletes& athletes)
{
    bool result = true;

    if(athletes.empty())
    {
        return true;
    }

    // Get all the Athletes from Database
    AthletesMap existingDBathletesMap;
    AthleteDataModel::fetch(dbSession, existingDBathletesMap);

    unsigned long insertCount = 0;
    unsigned long updateCount = 0;
    Athletes::const_iterator iter;
    for(iter = athletes.begin(); iter != athletes.end(); ++iter)
    {
        Athlete* pAthlete = *iter;
        bool saveResult = true;

        AthletesMap::iterator existingDBathleteIter = existingDBathletesMap.find(pAthlete->ID);
        if(existingDBathleteIter == existingDBathletesMap.end())
        {
            saveResult = AthleteDataModel::insert(dbSession, *pAthlete);
            insertCount++;
        }
        else
        {
            Athlete* pExistingAthlete = existingDBathleteIter->second;

            if(!Athlete::compare(pAthlete, pExistingAthlete))
            {
                saveResult = AthleteDataModel::update(dbSession, *pAthlete);
                updateCount++;
            }
        }
        if(!saveResult)
        {
            poco_error(Poco::Logger::root(), "Athlete could not be saved to database for " + Poco::NumberFormatter::format(pAthlete->ID)
                       + " " + pAthlete->first_name + " " + pAthlete->last_name);
            result = false;
        }
        // We dont remove any Athletes
    }

    if(insertCount > 0 || updateCount > 0)
    {
        poco_trace(Poco::Logger::root(), "Athletes reconciled with " + Poco::NumberFormatter::format(insertCount) + " inserts and " + Poco::NumberFormatter::format(updateCount) + " updates.");
    }

    AthleteDataModel::free(existingDBathletesMap);

    return result;
}

STATIC void AthleteDataModel::freeAthlete(Athlete* pAthlete)
{
    if(pAthlete != NULL)
    {
        delete pAthlete;
    }
}

STATIC void AthleteDataModel::free(Athletes& athletes)
{
    std::for_each(athletes.begin(), athletes.end(), AthleteDataModel::freeAthlete);
    athletes.clear();
}

STATIC void AthleteDataModel::freeAthletePair(std::pair<const unsigned long, Athlete*>& athletePair)
{
    if(athletePair.second != NULL)
    {
        delete athletePair.second;
    }
}

STATIC void AthleteDataModel::free(AthletesMap& athletesMap)
{
    std::for_each(athletesMap.begin(), athletesMap.end(), AthleteDataModel::freeAthletePair);
    athletesMap.clear();
}


