Building Poco library framework
--------------------------------
- if choosing to install from source

	Use the --everything to ensure we get MySQL

	$ ./configure --everything


	$ make -j 8

	$ make install

- installs to /usr/local/include and /usr/local/lib

 (maybe it should be putting it in /usr/local/lib64)


Libraries
----------
- Uses google gumbo parser for parsing HTML pages
	https://github.com/google/gumbo-parser/tree/master/examples
	
- Uses libhtmltidy to fix broken HTML pages that would otherwise cause gumbo parser to fail.
	https://github.com/htacg/tidy-html5/tree/next/README
	http://tidy.sourceforge.net/libintro.html

TODO
-------
DONE - make ResultsScraper descend from Scraper

