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
