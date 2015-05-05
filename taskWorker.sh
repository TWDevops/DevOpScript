#!/bin/bash
BASEDIR=$(dirname $0)
CURLCMD="/usr/bin/curl"
JQCMD="/usr/bin/jq"
apiManIp="127.0.0.1"
apiManPort="3000"

#取得 task list
taskJson=$($CURLCMD http://$apiManIp:$apiManPort/mod/task/gettask/deploy)
#echo $json_input
#ping $(echo $json_input|$JQCMD -r '.taskParams.apServIp')
taskId=$(echo $taskJson|$JQCMD -r '._id')
srcPath=$(echo $taskJson|$JQCMD -r '.taskParams.srcPath')
apServIp=$(echo $taskJson|$JQCMD -r '.taskParams.apServIp')
apiId=$(echo $taskJson|$JQCMD -r '.taskParams.apiId')
apiVerIdx=$(echo $taskJson|$JQCMD -r '.taskParams.apiVerIdx')
apiVerDeploy=$(echo $taskJson|$JQCMD -r '.taskParams.deploy')
#echo "BASEDIR:  $BASEDIR"
#echo "taskId:   $taskId"
#echo "srcPath:  $srcPath"
#echo "apServIP: $apServIp"
if [ "$taskId" == "null" ]; then
    echo "no task list."
    exit 1
fi

#鎖定task
startJson=$($CURLCMD http://$apiManIp:$apiManPort/mod/task/setTask/$taskId/start)
echo $startJson
startState=$(echo $startJson|$JQCMD -r '.state')
startnModified=$(echo $startJson|$JQCMD -r '.nModified')
#echo "$startState"
#echo "$startnModified"
if [ "$startState" != "0" ]; then
    echo "update error"
    exit 1
fi

if [ "$startnModified" == "0" ]; then
    echo "can not lock task($taskId)"
    exit 1
fi

#執行 Deploy
$BASEDIR/testdeploy.sh $apServIp $srcPath

#結束task
doneJson=$($CURLCMD http://$apiManIp:$apiManPort/mod/task/setTask/$taskId/done)
echo $doneJson
doneState=$(echo $doneJson|$JQCMD -r '.state')
donenModified=$(echo $doneJson|$JQCMD -r '.nModified')
if [ "$doneState" != "0" ]; then
    echo "update error"
    exit 1
fi

if [ "$donenModified" == "0" ]; then
    echo "can not change task($taskId) status."
    exit 1
fi

#變更api deploy 狀態
upDeployStJson=$($CURLCMD http://$apiManIp:$apiManPort/mod/api/updatelv/$apiId/$apiVerDeploy/$apiVerIdx)
upDeployState=$(echo $upDeployStJson|$JQCMD -r '.state')
upDeployModified=$(echo $upDeployStJson|$JQCMD -r '.result.nModified')
if [ "$upDeployState" != "0" ]; then
    echo "update error"
    exit 1
fi

if [ "$upDeployModified" == "0" ]; then
    echo "can not change api($apiId) deploy status."
    exit 1
fi

echo "Deploy Success."
exit 0
