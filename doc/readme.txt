

Building PRPL and installation 
------------------------------
- if installing on deploying host
	sudo useradd prpl
	sudo passwd prpl
	# Give prpl user sudo temporarily whilst we install
	sudo echo "prpl ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/91-prpl
	sudo usermod -a -G wheel prpl  # best not to do this - less secure
	su - prpl
	echo "export LD_LIBRARY_PATH=.:/opt/prpl/src/../bin:/lib64:/lib:/usr/lib64/:/usr/lib:/usr/local/lib64:/usr/local/lib" >> ~/.bashrc
	export LD_LIBRARY_PATH=.:/opt/prpl/src/../bin:/lib64:/lib:/usr/lib64/:/usr/lib:/usr/local/lib64:/usr/local/lib
	
	sudo yum install git cmake

- Build poco into prpl/src - follow instructions in section "Building Poco library framework"
	cd prpl/src
	git clone -b poco-1.7.8 https://github.com/pocoproject/poco.git

	# On Centos 7 :
	sudo yum install gcc gcc-c++ mariadb mariadb-devel openssl-devel libtool-ltdl-devel

	# Use the --everything to ensure we get MySQL
	./configure --everything --omit=Data/ODBC --no-samples --no-tests
	make 
	make install
	
cd prpl/src/externals
	git clone https://github.com/google/gumbo-parser
	cd gumbo-parser
	sudo yum install libtool
	./autogen.sh
	./configure
	make
	sudo make install

cd prpl/src/externals/libtidy
	git clone https://github.com/htacg/tidy-html5
	cd tidy-html5
	cd build/cmake
	./build-me.sh
	sudo make install

- Can now build PRPL into /opt/prpl
	cd prpl/src
	./build.sh -clean -cpu 2

- Now remove sudo from user prpl
	sudo rm /etc/sudoers.d/91-prpl
	sudo usermod -g prpl prpl
	export LD_LIBRARY_PATH=/lib64:/usr/lib64:/usr/local/lib64:/lib:/usr/lib:/usr/local/lib
	

Libraries
----------
- Poco framework

- Uses google gumbo parser for parsing HTML pages
	https://github.com/google/gumbo-parser/tree/master/examples
	
- Uses libhtmltidy to fix broken HTML pages that would otherwise cause gumbo parser to fail.
	https://github.com/htacg/tidy-html5/tree/next/README
	http://tidy.sourceforge.net/libintro.html


Building Poco library framework
--------------------------------
- if choosing to install from source

	cd prpl/src
	git clone -b poco-1.7.8 https://github.com/pocoproject/poco.git

	# On Centos 7 :
	sudo yum install gcc gcc-c++ mariadb mariadb-devel openssl-devel libtool-ltdl-devel
	
	Use the --everything to ensure we get MySQL

	$ ./configure --everything


	# Will need unixODBC-devel for installing poco/Data and prevent it complaining about missing sqlext.h
	sudo yum install unixODBC-devel gcc -

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


SystemD setup 
---------------
sudo cp prpl/doc/prpld.service /usr/lib/systemd/system/
sudo systemctl daemon-reload
sudo systemctl status prpld
sudo systemctl enable prpld
sudo systemctl start prpld


TODO
-------
- Convert embedded html to using Google CTemplate library
- add dynamic calculation of max points [ NOT CONVINCED EASILY DOABLE ]
	- need to read all results available and get max runners per gender.
		- round this up to the next 100th and then add 100 e.g. 312 -> 400 then +100 = 500
	- if its the 1st year then calculate as above whilst proceeding through 
		- If number of runners exceeds max points then recalculate maxpoints and its league
	- if 2nd+ year then use maxpoints from prior year + 30% growth, then recalculate based on this.
- Add a "Last/Next check time" for saturday mornings to help prevent frequent refreshers
- Add email notification form, so can get email when a league is updated.

