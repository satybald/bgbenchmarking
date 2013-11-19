#!/bin/sh

BG_HOME="/home/sayats/mongo/BGClient.new"

HOST_IP=10.0.0.240
DB_NAME=bg_db_v2
THREAD_COUNT=10
INSERT_IMAGE=true
MAX_EXEC_TIME=100
USER_COUNT=1000

CreateSchema(){

    ls -la $BG_HOME/workloads/populateDB
    java -cp $BG_HOME/build/bg.jar:$BG_HOME/db/MongoDB/lib/* edu.usc.bg.base.Client \
        -schema -db mongoDB.MongoDbClient -p mongodb.url=$HOST_IP:27017 -p mongodb.database=$DB_NAME

    ret=$?
    if [ "$ret" -ne "0" ] 
    then
        echo "ERROR: in Creating Schema $ret"
        exit 1
    else
        echo "DONE: $ret"
    fi

}

PopulateData(){
    ls -la $BG_HOME/workloads/populateDB
    java -cp $BG_HOME/build/bg.jar:$BG_HOME/db/MongoDB/lib/* edu.usc.bg.base.Client \
    -load -db mongoDB.MongoDbClient -P $BG_HOME/workloads/populateDB \
    -p mongodb.url=$HOST_IP:27017 -p insertimage=$INSERT_IMAGE -p threadcount=$THREAD_COUNT \
    -p mongodb.writeConcern=strict -p mongodb.database=$DB_NAME

    ret=$?
    if [ "$ret" -ne "0" ] 
    then
        echo "ERROR: in PopulateData $ret"
        exit 1
    else
        echo "DONE: $ret"
    fi

}

Workload(){
    java -Xmx1024M -cp $BG_HOME/build/bg.jar:$BG_HOME/db/MongoDB/lib/* edu.usc.bg.base.Client \
    -t -db mongoDB.MongoDbClient \
    -P $BG_HOME/workloads/SymmetricHighUpdateActions -s \
    -p mongodb.url=$HOST_IP:27017 -p threadcount=$THREAD_COUNT -p mongodb.writeConcern=strict \
    -p mongodb.database=$DB_NAME -p exportfile=thread0.10.07.txt -p ratingmode=false \
    -p maxexecutiontime=$MAX_EXEC_TIME -p initapproach=querydata -p usercount=$USER_COUNT

    ret=$?
    if [ "$ret" -ne "0" ] 
    then
        echo "ERROR: in benchmarking $ret"
        exit 1
    else
        echo "DONE: $ret"
    fi

}
# -t -db MongoDB.MongoDbClient -P workloads/ViewProfileAction -s -p threadcount=1 -p mongodb.writeConcern=normal -p mongodb.database=benchmark -p maxexecutiontime=100 -p mongodb.url=10.0.0.122:27017 -p ratingmode=false 

# -t -db TestDS.TestDSClient -P C:/BG/workloads/MixOfAction -p maxexecutiontime=30 -p usercount=1000 -p initapproach=querydata
# }

# Stats(){
#     java -cp build/bg.jar:db/MongoDB/lib/* edu.usc.bg.base.Client -stats -db mongoDB.MongoDbClient -P $BG_HOME/workloads/SymmetricHighUpdateActions -s -p mongodb.url=127.0.0.1:27017 -p threadcount=1 -p mongodb.writeConcern="normal" -p mongodb.database=local -p maxexecutiontime=600 -p usercount=100 -p initapproach=querydata -p exportfile=thread1.txt -p ratingmode=false 
# }

echo "****** Creating Schema ******"
CreateSchema

echo "****** Populating Data ******"
PopulateData

echo "****** Benchmarking  ********"
Workload


