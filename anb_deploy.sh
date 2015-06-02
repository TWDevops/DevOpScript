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
	echo '{action:push,name:getlog,status:OK}'
else
	echo '{action:push,name:getlog,status:FAILED}'
fi

#複製檢查shell 過去
pushcheck=`ansible $1 -s -m copy -a "src=$home/check.sh dest=$home/check.sh owner=root group=root mode=755"|grep success|cut -d '|' -f2|cut -d ' ' -f2|cut -d ' ' -f1`
if [ $pushcheck == "success" ];then
        echo '{action:push,name:checklog,status:OK}'
else
        echo '{action:push,name:checklog,status:FAILED}'
fi

#複製codeback shell 過去
pushcodeback=`ansible $1 -s -m copy -a "src=$home/codeback.sh dest=$home/codeback.sh owner=root group=root mode=755"|grep success|cut -d '|' -f2|cut -d ' ' -f2|cut -d ' ' -f1`
if [ $pushcodeback == "success" ];then
        echo '{action:push,name:codebackup,status:OK}'
else
        echo '{action:push,name:codebackup,status:FAILED}'
fi

#複製還原code shell 過去
#pushreback=`ansible $1 -s -m copy -a "src=$home/recode.sh dest=$home/recode.sh owner=root group=root mode=755"|grep success|cut -d '|' -f2|cut -d ' ' -f2|cut -d ' ' -f1`
#if [ $pushreback == "success" ];then
#        echo '{action:push,name:codereback,status:OK}'
#else
#        echo '{action:push,name:codereback,status:FAILED}'
#fi

#backup code
backupcode=`ansible $1 -s -m shell -a "$home/codeback.sh $codedir"|grep success|cut -d '|' -f2|cut -d ' ' -f2|cut -d ' ' -f1`
if [ $backupcode == "success" ];then
        echo '{action:run,name:codebackup,status:OK}'
else
        echo '{action:run,name:codebackup,status:FAILED}'
fi


#執行讀取log shell
runget=`ansible $1 -s -m shell -a "$home/getlog.sh"|grep success|cut -d '|' -f2|cut -d ' ' -f2|cut -d ' ' -f1`
if [ $runget == "success" ];then
	sleep 2
	echo '{action:run,name:getlog,status:OK}'
else
        echo '{action:run,name:getlog,status:FAILED}'
fi

#從git 下載程式
gitcode=`ansible $1 -s -m git -a "repo=$2 dest=/tmp/$tmpdir"|grep success|cut -d '|' -f2|cut -d ' ' -f2|cut -d ' ' -f1`
if [ $gitcode == "success" ];then
	aar=`ansible $1 -s -a "ls /tmp/$tmpdir"|grep aar`
	echo '{action:run,name:gitcode,status:OK}'
else
        echo '{action:run,name:gitcode,status:FAILED}'
fi

#將程式搬移至執行目錄
upcode=`ansible $1 -s -a "cp /tmp/$tmpdir/$aar $codedir"|grep success|cut -d '|' -f2|cut -d ' ' -f2|cut -d ' ' -f1`
if [ $upcode == "success" ];then
	echo '{action:run,name:uploadcode,status:OK}'
else
        echo '{action:run,name:uploadcode,status:FAILED}'
fi

#刪除暫存下載目錄
rmtmp=`ansible $1 -s -a "rm -rf /tmp/$tmpdir"|grep success|cut -d '|' -f2|cut -d ' ' -f2|cut -d ' ' -f1`
if [ $rmtmp == "success" ];then
	echo '{action:run,name:cleartmp,status:OK}'
else
        echo '{action:run,name:cleartmp,status:FAILED}'
fi

#執行檢查shell
runcheck=`ansible $1 -s -m shell -a "$home/check.sh $aar"|grep success|cut -d '|' -f2|cut -d ' ' -f2|cut -d ' ' -f1`
if [ $runcheck == "success" ];then
	echo '{action:run,name:checklog,status:OK}'
else
        echo '{action:run,name:checklog,status:FAILED}'
	ansible $1 -s -m shell -a "$home/recode.sh $codedir"
	echo '{action:run,name:restorecode,status:OK}'
fi
	
#掛上nginx
#upnginx=`ansible $1 -s -a "curl -s -o /dev/null -d {"status":0} http://localhost:9763/ServStat"|grep success|cut -d '|' -f2|cut -d ' ' -f2|cut -d ' ' -f1`
#if [ $upnginx == "success" ];then
#	echo up of nginx OK!
#else
#       echo up of nginx FAILED!
#fi
