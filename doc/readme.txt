Building Poco library framework
--------------------------------
- if choosing to install from source

	Use the --everything to ensure we get MySQL

	$ ./configure --everything


	$ make -j 8

	$ make install

- installs to /usr/local/include and /usr/local/lib

 (maybe it should be putting it in /usr/local/lib64)


Building libtidy
--------------------------------
- libtidy seems to have many forks. The one on Fed23 works and doesnt wrap the output. The one in RHEL6 wraps the text and causes issues.

cd src/external/libtidy

mv tidy-20091203cvs-format.patch tidy
cd tidy
patch -p1 -b < tidy-20091203cvs-format.patch
chmod +x ./build/gnuauto/setup.sh
./build/gnuauto/setup.sh
./configure --disable-static --disable-dependency-tracking
make -j 4
sudo make install



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

