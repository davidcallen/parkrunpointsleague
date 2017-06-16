#ifndef LogFormatter_INCLUDED
#define LogFormatter_INCLUDED

#include "Common.h"

#include <Poco/Formatter.h>
#include <Poco/Message.h>

class LogFormatter : public Poco::Formatter
{
public:
	LogFormatter();

	virtual ~LogFormatter();

protected:
	virtual void format(const Poco::Message& message, std::string& text);
};

#endif // LogFormatter_INCLUDED
