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


#抽離nginx
echo down of nginx
ansible $1 -s -a "curl -s -o /dev/null -d {"status":1} http://localhost:9763/ServStat"

sleep 2
echo push log shell 
#複製讀取log shell 過去
ansible $1 -s -m copy -a "src=/home/deploy/getlog.sh dest=/home/deploy/getlog.sh owner=root group=root mode=755 state=touch"

sleep 2
echo run log shell
#執行讀取log shell
ansible $1 -s -m shell -a "/home/deploy/getlog.sh"

sleep 2
echo git clone code
#從git 下載程式
ansible $1 -s -m git -a "repo=$2 dest=/tmp/$tmpdir"
aar=`ansible $1 -s -a "ls /tmp/$tmpdir"|grep aar`

echo upload code
#將程式搬移至執行目錄
ansible $1 -s -a "cp /tmp/$tmpdir/$aar $codedir"

echo clear tmp
#刪除暫存下載目錄
ansible $1 -s -a "rm -rf /tmp/$tmpdir"

echo push check shell
#複製檢查shell 過去
ansible $1 -s -m copy -a "src=/home/deploy/check.sh dest=/home/deploy/check.sh owner=root group=root mode=755 state=touch"

echo run check shell
#執行檢查shell
ansible $1 -s -m shell -a "/home/deploy/check.sh $aar"

echo up of nginx
#掛上nginx
ansible $1 -s -a "curl -s -o /dev/null -d {"status":0} http://localhost:9763/ServStat"
