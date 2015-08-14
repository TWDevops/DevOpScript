#!/bin/bash
DEVOPSYS_IP="10.240.1.164"
NFS_SHARE="/opt/jk_builds/"
echo "Hello Shell"
echo "BUILD_NUMBER : ${BUILD_NUMBER}"
echo "BRANCH : ${GIT_BRANCH}"
echo "JOB_NAME : ${JOB_NAME}"
echo "BUILD_ID : ${BUILD_ID}"
echo "COMMIT_ID : ${GIT_COMMIT}"
echo "WORKSPACE : ${WORKSPACE}"
echo "BUILD_URL : ${BUILD_URL}"
echo "JOB_URL : ${JOB_URL}"
job_status=`curl --silent ${BUILD_URL}api/json | tr -s "{[]}," "\n"|tr -d '"'|grep result|cut -d":" -f2`
echo "result:$job_status"
if [ "$job_status" == "SUCCESS" ]
then
    echo "OK"
    cd ${WORKSPACE}/dist
    #tar zcvf ${NFS_SHARE}/${JOB_NAME}_${BUILD_ID}.tar.gz ./*
    WARFILES=$(ls *.war)
    if [ ! -d "${NFS_SHARE}/${JOB_NAME}/${GIT_COMMIT}" ];then
        mkdir -p ${NFS_SHARE}/${JOB_NAME}/${GIT_COMMIT}
    fi
    cp $WARFILES ${NFS_SHARE}/${JOB_NAME}/${GIT_COMMIT}
    WARARRAY=""
    declare -i idx=0
    for filename in $WARFILES
    do
        if [ $idx != 0 ];then
            WARARRAY="$WARARRAY,"
        fi
        WARARRAY="$WARARRAY\"$filename\""
        idx=$idx+1
    done
    curl --silent -H "Content-Type: application/json" -X POST -d "{ \"JOB_NAME\" : \"${JOB_NAME}\", \"BRANCH\" : \"${GIT_BRANCH}\", \"BUILD_ID\" : \"${BUILD_ID}\", \"COMMIT_ID\" : \"${GIT_COMMIT}\", \"JOB_STATUS\" : \"${job_status}\", \"WORKSPACE\" : \"${WORKSPACE}\", \"BUILD_URL\" : \"${BUILD_URL}\", \"PKG_FILE\" : [$WARARRAY] }" http://${DEVOPSYS_IP}/mod/report/receive/ci
else
  echo "BUILD FAILURE: Other build is unsuccessful or status could not be obtained."
  exit 1
fi
