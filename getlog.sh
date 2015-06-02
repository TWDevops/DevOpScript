#!/bin/bash
nohup tail -f -n0 /usr/local/wso2as/repository/logs/wso2carbon.log > /home/deploy/deploy.log &
