#!/bin/bash

# from: https://cloud.google.com/solutions/running-rstudio-server-on-a-cloud-dataproc-cluster and https://www.rstudio.com/products/rstudio/download-server/
# this is just a script of all the necessary steps to get the system up and running, and finishing with adding the test user
# note: the test user password will have to be entered manually

# install R and gdebi-core
sudo apt-get update &&
sudo apt-get install -y r-base r-base-dev libcurl4-openssl-dev libssl-dev libxml2-dev gdebi-core &&

# install RStudio Server
wget https://download2.rstudio.org/server/debian9/x86_64/rstudio-server-1.2.1335-amd64.deb &&
sudo gdebi --n rstudio-server-1.2.1335-amd64.deb &&

# install sparklyr package
sudo su - -c "R -e \"install.packages('sparklyr',repos = 'http://cran.us.r-project.org')\"" &&

# add user called test
sudo adduser test
