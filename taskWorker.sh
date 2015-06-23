#!/bin/bash
BASEDIR=$(dirname $0)
CURLCMD="/usr/bin/curl -s"
JQCMD="/usr/bin/jq"

if [ "$devops_env" == "LAB" ]; then
	apiManIp="10.240.1.164"
else
	apiManIp="127.0.0.1"
fi
apiManPort="8080"

#取得 task list
taskJson=$($CURLCMD "http://$apiManIp:$apiManPort/mod/task/api/deploy")
taskId=$(echo $taskJson|$JQCMD -r 'keys[]')
if [ -z "$taskId" ] || [ "$taskId" == "null" ]; then
    echo "no task list."
    exit 0
fi
jsonRoot=".[\"$taskId\"]"
gitUrl=$(echo $taskJson|$JQCMD -r "$jsonRoot.taskParams.gitUrl")
apServIp=$(echo $taskJson|$JQCMD -r "$jsonRoot.taskParams.apServIp")
branch=$(echo $taskJson|$JQCMD -r "$jsonRoot.taskParams.branch")
if [ -z $branch ]; then
    echo "no branch"
    exit 1
fi
#是否自動 on-line: 1:是, 0:否
autoOnline=$(echo $taskJson|$JQCMD -r "$jsonRoot.taskParams.online")
echo $taskId
echo $gitUrl
echo $apServIp
echo $branch
echo $autoOnline
#鎖定task
startJson=$($CURLCMD "http://$apiManIp:$apiManPort/mod/task/setstatus/$taskId/start")
#echo "http://$apiManIp:$apiManPort/mod/task/gettask/deploy"
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

#Set AS Server Off-line
#$CURLCMD -o /dev/null -d {"status":1} http://$apServIp:9763/ServStat
#until [ "$nxstatus" == "down" ]
#do
#	/bin/sleep 3
#	nxstatus=$($CURLCMD "http://nginx.kilait.com/status?format=json"|jq -r '.servers.server[] | select(.name | contains("'$apServIp'")) | .status')
#	echo "nxstatus=$nxstatus"
#done

#執行 Deploy
if [ "$devops_env" == "LAB" ]; then
	deploy_st=$($BASEDIR/anb_deploy.sh $apServIp $gitUrl $branch)
	for anb_stat in $deploy_st
	do
		cmd_name=$(echo $anb_stat|$JQCMD -r '.name')
		cmd_stat=$(echo $anb_stat|$JQCMD -r '.status')
		if [ "$cmd_stat" != "OK" ]; then
			echo "Error on $cmd_name"
			$CURLCMD "http://$apiManIp:$apiManPort/mod/task/setstatus/$taskId/error"
			exit 1
		fi
		echo "$cmd_name was OK."
	done
else
	echo "$BASEDIR/anb_deploy.sh $apServIp $gitUrl $branch"
fi

##Set AS Server On-line
if [ "autoOnline" == "1" ];then
    $CURLCMD -o /dev/null -d {"status":0} http://$apServIp:9763/ServStat
    until [ "$nxstatus" == "up" ]
    do
	/bin/sleep 3
	nxstatus=$($CURLCMD "http://nginx.kilait.com/status?format=json"|jq -r '.servers.server[] | select(.name | contains("'$apServIp'")) | .status')
	echo "nxstatus=$nxstatus"
    done
fi

#結束task
doneJson=$($CURLCMD "http://$apiManIp:$apiManPort/mod/task/setstatus/$taskId/done")
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

echo "Deploy Success."
exit 0

