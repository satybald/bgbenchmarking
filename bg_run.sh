#!/bin/sh

BG_HOME="/Users/tashiba/Documents/Sayat/USC/CS685/BGClient/BGNew"

DROP_DB=0
SHARD=0
SCHEMA=1
POP_DATA=1
WORK=0

SHARD_TABLE="users"
HOST_IP=127.0.0.1
DB_NAME=bg_singlev10
THREAD_COUNT=10
INSERT_IMAGE=true
MAX_EXEC_TIME=600
USER_COUNT=100000
RES_PER_USER=1000
FRIEND_PER_USER=1000

dropDB(){
   mongo $HOST_IP/$DB_NAME <<EOF
   use $DB_NAME
   db.dropDatabase();
EOF
}

CreateSchema(){
    java -cp $BG_HOME/build/bg.jar:$BG_HOME/db/MongoDB/lib/* edu.usc.bg.BGMainClass \
    onetime -schema -db mongoDB.MongoDbClient -p mongodb.url=$HOST_IP:27017 -p mongodb.database=$DB_NAME

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
   sh.shardCollection("$DB_NAME.$SHARD_TABLE", {_id: "hashed"})
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
    # -p userworkload="edu.usc.bg.workloads.UserWorkload" -p friendshipworkload="edu.usc.bg.workloads.FriendshipWorkload" \
    # -p resourceworkload="edu.usc.bg.workloads.ResourceWorkload" \
#-p requestdistribution=dzipfian -p zipfianmean=0.27
    # -P $BG_HOME/workloads/populateDB \
PopulateData(){
    java -cp $BG_HOME/build/bg.jar:$BG_HOME/db/MongoDB/lib/* edu.usc.bg.BGMainClass \
    onetime -load -db mongoDB.MongoDbClient \
    -p mongodb.url=$HOST_IP:27017 -p insertimage=$INSERT_IMAGE -p threadcount=$THREAD_COUNT \
    -p mongodb.writeConcern=strict -p mongodb.database=$DB_NAME \
    -p userworkload="edu.usc.bg.workloads.UserWorkload" -p friendshipworkload="edu.usc.bg.workloads.FriendshipWorkload" \
    -p resourceworkload="edu.usc.bg.workloads.ResourceWorkload" \
    -p usercount=$USER_COUNT -p useroffset=0 -p confperc=1 \
    -p resourcecountperuser=$RES_PER_USER -p friendcountperuser=$FRIEND_PER_USER \
    -p requestdistribution=dzipfian -p zipfianmean=0.27

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
    java -Xmx1024M -cp $BG_HOME/build/bg.jar:$BG_HOME/db/MongoDB/lib/* edu.usc.bg.BGMainClass \
    onetime -t -db mongoDB.MongoDbClient \
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
if [ "$DROP_DB" -eq 1 ]
    then
    echo "****** Drop DB ******"
    dropDB
fi

if [ "$SCHEMA" -eq 1 ]
    then
    echo "****** Creating Schema ******"
    CreateSchema
fi

if [ "$SHARD" -eq 1 ]
    then
    echo "****** Sharding Data ******"
    ShardDB
fi

if [ "$POP_DATA" -eq 1 ]
    then
    echo "****** Populating Data ******"
    PopulateData
fi

if [ "$WORK" -eq 1 ]
    then
    echo "****** Benchmarking  ********"
    Workload
fi


