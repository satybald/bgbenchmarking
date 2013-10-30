#!/bin/sh
mkdir -p /usr/local/mongo/data/configdb
mongod --configsvr --dbpath /usr/local/mongo/data/configdb --port 27019
