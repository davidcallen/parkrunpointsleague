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
#include "EventResultItem.h"

EventResultItem::EventResultItem()
	: ID(0), eventResultID(0), position(0), genderPosition(Poco::NULL_GENERIC), gender(Poco::NULL_GENERIC),
	athleteID(Poco::NULL_GENERIC), durationSecs(Poco::NULL_GENERIC)
{

}

EventResultItem::EventResultItem(const unsigned long _ID, const unsigned long _eventResultID, const unsigned long _position,
                                 Poco::Nullable<unsigned long> _genderPosition, Poco::Nullable<std::string> _gender, Poco::Nullable<unsigned long> _athleteID,
                                 Poco::Nullable<unsigned long> _durationSecs)
	: ID(_ID), eventResultID(_eventResultID), position(_position), genderPosition(_genderPosition), gender(_gender),
	athleteID(_athleteID), durationSecs(_durationSecs)
{

}

Poco::Timespan EventResultItem::getDurationTimespan() const
{
    Poco::Timespan durationTimespan;
    if(!durationSecs.isNull())
    {
        durationTimespan.assign(0, 0, 0, durationSecs.value(), 0);
    }

    return durationTimespan;
}
