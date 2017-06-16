#include "LogFormatter.h"

#include <iostream>

LogFormatter::LogFormatter() 
{
}

VIRTUAL LogFormatter::~LogFormatter()
{
}

VIRTUAL void LogFormatter::format(const Poco::Message& message, std::string& text)
{
	// TODO : may be faster to use this instead of the PatternFormatter
}
