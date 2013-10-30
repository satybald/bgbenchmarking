#!/bin/sh
mkdir -p /usr/local/mongo/data/configdb
mongod --configsvr --dbpath /data/configdb --port 27019
