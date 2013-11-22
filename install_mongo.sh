#!/bin/sh
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10
echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | sudo tee /etc/apt/sources.list.d/mongodb.list
sudo apt-get update 
mkdir -p /usr/local/mongo/data/db/
sudo apt-get install mongodb-10gen
sudo service mongodb stop
nohup mongod --dbpath /usr/local/mongo/data/db
