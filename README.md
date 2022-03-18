# parkrunpointsleague 
ParkRun Points League (prpl) website for calculating and displaying League tables from Park Run events.

Created in C++ using the [Poco framework](https://docs.pocoproject.org/current/).

It is licensed under the GPL v3.

Data is stored in MariaDB database.

It is designed to pull (scrape) data from ParkRun website, and aggregate it to create the League table.

This website is no longer hosted on www.parkrunpointsleage.org due to concerns over GDPR. Its primary purpose now is to act as a "showcase" and Lab environment for my DevOps and AWS practices.
 
See ./doc/readme.txt for instructions on building from source code.

See ./deploy for deployments on various Cloud platforms (AWS, GCP).  Covers deployment using traditional VMs and also within ECS and Kubernetes.
