#!/bin/bash
date=`date +%Y%m%d%H%M`
deldate=`date +%Y%m%d`
if [ -d /opt/codeback ];then
	mv /opt/codeback /opt/codeback-$date
	mkdir /opt/codeback
	find $1 -type f -name "*.aar" -exec cp {} /opt/codeback/ \;
else
	mkdir /opt/codeback
	find $1 -type f -name "*.aar" -exec cp {} /opt/codeback/ \;
fi
find /opt -type d -name "codeback" -mtime +5 -exec rm -rf {} \;
