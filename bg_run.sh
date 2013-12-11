#!/bin/sh

BG_HOME="/home/dblab/mongo/BG"

DROP_DB=1
SHARD=1
SCHEMA=1
POP_DATA=1
WORK=1

SHARD_TABLE="users"
SHARD_RES="resources"
HOST_IP=10.0.0.130
PORT=27017
DB_NAME=bg2_shardUR_hash10K
THREAD_COUNT=10
INSERT_IMAGE=false
MAX_EXEC_TIME=100
USER_COUNT=10000
RES_PER_USER=10
FRIEND_PER_USER=10
WORKLOAD=SymmetricVeryLowUpdateActions
WRITECONCERN=normal

dropDB(){
   mongo $HOST_IP:$PORT/$DB_NAME <<EOF
   use $DB_NAME
   db.dropDatabase();
EOF
}

CreateSchema(){
    java -cp $BG_HOME/build/bg.jar:$BG_HOME/db/MongoDB/lib/* edu.usc.bg.BGMainClass \
    onetime -schema -db mongoDB.MongoDbClient -p mongodb.url=$HOST_IP:27017 -p mongodb.database=$DB_NAME -p port=$PORT

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
   #db.users.ensureIndex({ _id: "hashed"})
   #sh.shardCollection("$DB_NAME.$SHARD_TABLE", {_id: "hashed"})
mongo $HOST_IP:$PORT/$DB_NAME <<EOF
   sh.enableSharding("$DB_NAME");
   use $DB_NAME
   db.users.ensureIndex({ _id: "hashed"})
   sh.shardCollection("$DB_NAME.$SHARD_TABLE", {_id: "hashed"})
   sh.shardCollection("$DB_NAME.resources", {walluserid:"hashed"})

EOF

#mongo $HOST_IP:$PORT/$DB_NAME <<EOF
#   sh.enableSharding("$DB_NAME");
#   use $DB_NAME
#   sh.shardCollection("$DB_NAME.$SHARD_TABLE", {_id: 1})
#EOF
  
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
    onetime -loadindex -db mongoDB.MongoDbClient \
    -p mongodb.url=$HOST_IP:$PORT -p insertimage=$INSERT_IMAGE -p threadcount=$THREAD_COUNT \
    -p mongodb.writeConcern=$WRITECONCERN -p mongodb.database=$DB_NAME \
    -p usercount=$USER_COUNT \
    -p resourcecountperuser=$RES_PER_USER -p friendcountperuser=$FRIEND_PER_USER \
    -P $BG_HOME/workloads/populateDB

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
    java -Xmx10G -cp $BG_HOME/build/bg.jar:$BG_HOME/db/MongoDB/lib/* edu.usc.bg.BGMainClass \
    onetime -t -db mongoDB.MongoDbClient \
    -P $BG_HOME/workloads/$WORKLOAD -s \
    -p mongodb.url=$HOST_IP:$PORT -p threadcount=$THREAD_COUNT -p mongodb.writeConcern=$WRITECONCERN \
    -p mongodb.database=$DB_NAME -p exportfile=thread0.10.07.txt -p ratingmode=false \
    -p maxexecutiontime=$MAX_EXEC_TIME -p initapproach=deterministic -p usercount=$USER_COUNT \
    -p resourcecountperuser=$RES_PER_USER -p friendcountperuser=$FRIEND_PER_USER \
    -p numloadthreads=10 \
    -p warmup=1000 \
    -P $BG_HOME/workloads/populateDB

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


