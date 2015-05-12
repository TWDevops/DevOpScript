#!/bin/bash
genpasswd() {
        local l=$1
        [ "$l" == "" ] && l=16
        tr -dc A-Za-z0-9_ < /dev/urandom | head -c ${l} | xargs
}

tmpdir=$(genpasswd 4)
host=$1
git=$2
codedir=/usr/local/wso2as/repository/deployment/server/axis2services/
home=/home/deploy

#抽離nginx
#downnginx=`ansible $1 -s -a "curl -s -o /dev/null -d {"status":1} http://localhost:9763/ServStat"|grep success|cut -d '|' -f2|cut -d ' ' -f2|cut -d ' ' -f1`
#if [ $downnginx == "success" ];then
#	echo nginx down OK!
#else
#       echo nginx down FAILED!
#fi

#複製讀取log shell 過去
pushlog=`ansible $1 -s -m copy -a "src=$home/getlog.sh dest=$home/getlog.sh owner=root group=root mode=755"|grep success|cut -d '|' -f2|cut -d ' ' -f2|cut -d ' ' -f1`
if [ $pushlog == "success" ];then
	sleep 2
	echo push getlog sehll OK!
else
	echo push getlog sehll FAILED!
fi

#複製檢查shell 過去
pushcheck=`ansible $1 -s -m copy -a "src=$home/check.sh dest=$home/check.sh owner=root group=root mode=755"|grep success|cut -d '|' -f2|cut -d ' ' -f2|cut -d ' ' -f1`
if [ $pushcheck == "success" ];then
        echo pull check shell OK!
else
        echo pull check shell FAILED!
fi

#複製codeback shell 過去
pushcodeback=`ansible $1 -s -m copy -a "src=$home/codeback.sh dest=$home/codeback.sh owner=root group=root mode=755"|grep success|cut -d '|' -f2|cut -d ' ' -f2|cut -d ' ' -f1`
if [ $pushcodeback == "success" ];then
        echo push codeback shell OK!
else
        echo push codeback shell FAILED!
fi

#複製還原code shell 過去
pushreback=`ansible $1 -s -m copy -a "src=$home/recode.sh dest=$home/recode.sh owner=root group=root mode=755"|grep success|cut -d '|' -f2|cut -d ' ' -f2|cut -d ' ' -f1`
if [ $pushreback == "success" ];then
        echo push codereback shell OK!
else
        echo push codereback shell FAILED!
fi

#執行讀取log shell
runget=`ansible $1 -s -m shell -a "$home/getlog.sh"|grep success|cut -d '|' -f2|cut -d ' ' -f2|cut -d ' ' -f1`
if [ $runget == "success" ];then
	sleep 2
	echo run getlog OK!
else
        echo run getlog FAILED!
fi

#從git 下載程式
gitcode=`ansible $1 -s -m git -a "repo=$2 dest=/tmp/$tmpdir"|grep success|cut -d '|' -f2|cut -d ' ' -f2|cut -d ' ' -f1`
if [ $gitcode == "success" ];then
	aar=`ansible $1 -s -a "ls /tmp/$tmpdir"|grep aar`
	echo git clone code OK!
else
        echo git clone code FAILED!
fi

#將程式搬移至執行目錄
upcode=`ansible $1 -s -a "cp /tmp/$tmpdir/$aar $codedir"|grep success|cut -d '|' -f2|cut -d ' ' -f2|cut -d ' ' -f1`
if [ $upcode == "success" ];then
	echo upload code OK!
else
        echo upload code FAILED!
fi

#刪除暫存下載目錄
rmtmp=`ansible $1 -s -a "rm -rf /tmp/$tmpdir"|grep success|cut -d '|' -f2|cut -d ' ' -f2|cut -d ' ' -f1`
if [ $rmtmp == "success" ];then
	echo clear tmp OK!
else
        echo clear tmp FAILED!
fi

#執行檢查shell
runcheck=`ansible $1 -s -m shell -a "$home/check.sh $aar"|grep success|cut -d '|' -f2|cut -d ' ' -f2|cut -d ' ' -f1`
if [ $runcheck == "success" ];then
	echo run check shell ok!
else
        echo run check shell FAILED!
	ansible $1 -s -m shell -a "$home/recode.sh $codedir"
	echo restore code to last version!!
fi
	
#掛上nginx
#upnginx=`ansible $1 -s -a "curl -s -o /dev/null -d {"status":0} http://localhost:9763/ServStat"|grep success|cut -d '|' -f2|cut -d ' ' -f2|cut -d ' ' -f1`
#if [ $upnginx == "success" ];then
#	echo up of nginx OK!
#else
#       echo up of nginx FAILED!
#fi