#!/bin/bash

#sharepath,logdate,locallogpath,reportpath,nodeNo,Date,
V_Node=1
V_SHAREPATH=/mnt/netapp
V_localpath=/home/gituser/logparsing

sudo tar xvzf /mnt/netapp/testRB/node4/atlassian-bitbucket-access-2019-08-27.tar.gz -C /home/gituser/logparsing/n1

sudo ./logp.sh ALL /home/gituser/logparsing/n1/STASH/log/ > /home/gituser/logparsing/8-27-19n1.txt

sudo rm -rf /home/gituser/logparsing/n1/STASH/log/atl*

sudo mv /home/gituser/logparsing/n1/STASH/log /mnt/netapp/testRB/reports/log082719n1
