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
