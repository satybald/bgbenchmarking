#!/bin/sh
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10
deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen
sudo apt-get update 
mkdir -p /usr/local/mongo/data/db/
sudo apt-get install mongodb
sudo service mongodb stop
mongod --dbpath /usr/local/mongo/data/db
