Building Poco library framework
--------------------------------
- if choosing to install from source

	cd prpl/src
	git clone -b poco-1.7.8 https://github.com/pocoproject/poco.git

	Use the --everything to ensure we get MySQL

	$ ./configure --everything


	# Will need unixODBC-devel for installing poco/Data and prevent it complaining about missing sqlext.h
	sudo yum install unixODBC-devel

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

- setup email server or Feedback page ?

- add dynamic calculation of max points [ NOT CONVINCED EASILY DOABLE ]
	- need to read all results available and get max runners per gender.
		- round this up to the next 100th and then add 100 e.g. 312 -> 400 then +100 = 500
	- if its the 1st year then calculate as above whilst proceeding through 
		- If number of runners exceeds max points then recalculate maxpoints and its league
	- if 2nd+ year then use maxpoints from prior year + 30% growth, then recalculate based on this.

- Add a "Last/Next check time" for saturday mornings to help prevent frequent refreshers
- Add email notification form, so can get email when a league is updated.

