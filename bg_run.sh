#!/bin/sh

BG_HOME="/usr/local/mongo/BGClient"
TABLE_NAME="users"
HOST_IP=10.0.0.240
DB_NAME=bg_single_shard
THREAD_COUNT=10
INSERT_IMAGE=true
MAX_EXEC_TIME=600
USER_COUNT=1000
RES_PER_USER=100
FRIEND_PER_USER=100

dropDB(){
   mongo $HOST_IP/$DB_NAME <<EOF
   use $DB_NAME
   db.dropDatabase();
EOF
}
CreateSchema(){
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

ShardDB(){
   mongo $HOST_IP/$DB_NAME <<EOF
   sh.enableSharding("$DB_NAME");
   use $DB_NAME
   db.users.ensureIndex({ _id: "hashed"})
   sh.shardCollection("$DB_NAME.$TABLE_NAME", {_id: "hashed"})
EOF
  
   ret=$?
    if [ "$ret" -ne "0" ]
    then
        echo "ERROR: in Sharding Schema $ret"
        exit 1
    else
        echo "DONE: $ret"
    fi

}

PopulateData(){
#   ls -la $BG_HOME/workloads/populateDB
    java -cp $BG_HOME/build/bg.jar:$BG_HOME/db/MongoDB/lib/* edu.usc.bg.base.Client \
    -load -db mongoDB.MongoDbClient \
    -P $BG_HOME/workloads/populateDB \
    -p resourcecountperuser=$RES_PER_USER -p friendcountperuser=$FRIEND_PER_USER -p usercount=$USER_COUNT \
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

#    -p confperc=1 -p numloadthreads=$THREAD_COUNT \
Workload(){
    java -cp $BG_HOME/build/bg.jar:$BG_HOME/db/MongoDB/lib/* edu.usc.bg.base.Client \
    -t -db mongoDB.MongoDbClient \
    -P $BG_HOME/workloads/SymmetricHighUpdateActions -s \
    -p mongodb.url=$HOST_IP:27017 -p threadcount=$THREAD_COUNT -p mongodb.writeConcern=strict \
    -p resourcecountperuser=$RES_PER_USER -p friendcountperuser=$FRIEND_PER_USER -p usercount=$USER_COUNT \
    -p mongodb.database=$DB_NAME \
    -p useroffset=0 -p confperc=1 -p numloadthreads=$THREAD_COUNT \
    -p maxexecutiontime=$MAX_EXEC_TIME -p initapproach=deterministic -p exportfile=fileexport.txt

    ret=$?
    if [ "$ret" -ne "0" ] 
    then
        echo "ERROR: in benchmarking $ret"
        exit 1
    else
        echo "DONE: $ret"
    fi

}
echo "****** Drop DB ******"
#dropDB

echo "****** Creating Schema ******"
#CreateSchema

echo "****** Sharding Schema ******"
#ShardDB

echo "****** Populating Data ******"
#PopulateData

echo "****** Benchmarking  ********"
Workload


