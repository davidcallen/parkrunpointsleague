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
#ifndef Common_INCLUDED
#define Common_INCLUDED

#include <Poco/Bugcheck.h>

// Psuedo Access Specifiers
#define IN
#define INOUT
#define OUT
#define VIRTUAL
#define PRIVATE
#define STATIC
#define FRIEND

// Make Poco trace and debug message macros (for some reason not available in Poco unless Poco has been built with POCO_LOG_DEBUG).
// See poco/Foundation/include/Poco/Logger.h.
#if defined(_DEBUG) || defined(POCO_LOG_DEBUG)
	#define poco_x_debug(logger, msg) \
		if ((logger).debug()) (logger).debug(msg, __FILE__, __LINE__); else (void) 0

	#define poco_x_debug_f1(logger, fmt, arg1) \
		if ((logger).debug()) (logger).debug(Poco::format((fmt), (arg1)), __FILE__, __LINE__); else (void) 0

	#define poco_x_debug_f2(logger, fmt, arg1, arg2) \
		if ((logger).debug()) (logger).debug(Poco::format((fmt), (arg1), (arg2)), __FILE__, __LINE__); else (void) 0

	#define poco_x_debug_f3(logger, fmt, arg1, arg2, arg3) \
		if ((logger).debug()) (logger).debug(Poco::format((fmt), (arg1), (arg2), (arg3)), __FILE__, __LINE__); else (void) 0

	#define poco_x_debug_f4(logger, fmt, arg1, arg2, arg3, arg4) \
		if ((logger).debug()) (logger).debug(Poco::format((fmt), (arg1), (arg2), (arg3), (arg4)), __FILE__, __LINE__); else (void) 0

	#define poco_x_trace(logger, msg) \
		if ((logger).trace()) (logger).trace(msg, __FILE__, __LINE__); else (void) 0

	#define poco_x_trace_f1(logger, fmt, arg1) \
		if ((logger).trace()) (logger).trace(Poco::format((fmt), (arg1)), __FILE__, __LINE__); else (void) 0

	#define poco_x_trace_f2(logger, fmt, arg1, arg2) \
		if ((logger).trace()) (logger).trace(Poco::format((fmt), (arg1), (arg2)), __FILE__, __LINE__); else (void) 0

	#define poco_x_trace_f3(logger, fmt, arg1, arg2, arg3) \
		if ((logger).trace()) (logger).trace(Poco::format((fmt), (arg1), (arg2), (arg3)), __FILE__, __LINE__); else (void) 0

	#define poco_x_trace_f4(logger, fmt, arg1, arg2, arg3, arg4) \
		if ((logger).trace()) (logger).trace(Poco::format((fmt), (arg1), (arg2), (arg3), (arg4)), __FILE__, __LINE__); else (void) 0
#endif

#endif // Common_INCLUDED
