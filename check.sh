#!/bin/bash
aar=$1
deploy=/usr/local/wso2as/repository/deployment/server/axis2services/
log=/home/deploy/deploy.log

sleep 15
check=`cat $log|grep $aar|grep "exists in the system"|grep ERROR|wc -l`
if [ $check != 0 ];then
   echo $1 is can not deploy
   aardel=/usr/local/wso2as/repository/deployment/server/axis2services/$aar
     if [ -e $aardel ];then
     rm -rf /usr/local/wso2as/repository/deployment/server/axis2services/$aar
     #call api to error
     killall tail
     exit 1
     fi
   else
   killall tail
   exit 0
   #call api to ok
fi
