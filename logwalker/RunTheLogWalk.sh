#!/bin/bash
#sharepath,logdate,locallogpath,reportpath,nodeNo,Date,
echo "P1: $1"
echo "P2: $2"

export V_NODE=$1
export V_DATE=$2

#V_NODE=3
V_SHAREPATH=/mnt/de
V_localpath=/home/gituser/logparsing
#V_DATE=2019-10-04
sudo tar xvzf $V_SHAREPATH/testRB/node$V_NODE/atlassian-bitbucket-access-$V_DATE.tar.gz -C $V_localpath/n$V_NODE

sudo $V_localpath/logp/logp.sh ALL $V_localpath/n$V_NODE/STASH/log/ > $V_localpath/$V_DATEn$V_NODE.txt

sudo rm -rf $V_localpath/n$V_NODE/STASH/log/atl*

sudo mv $V_localpath/n$V_NODE/STASH/log $V_SHAREPATH/testRB/reports/log$V_DATE-n$V_NODE

