#!/bin/bash

set -e
set -u

rm -f *.png

# Ensure that 'logparser' is in the PATH (e.g. run rebuild.sh or 'cabal copy')
DATE=`date "+%Y-%m"`
if [ "$#" -le "1" ]; then
    LOG_FILE=${1:-"/mnt/netapp/testRB/node1/STASH/log/atlassian-bitbucket-access-${DATE}*"}
else
    LOG_FILE=$@
fi

export GNUPLOT_LIB="gnuplot:."

time ./bin/logparser gitOperations ${LOG_FILE} +RTS -sstderr > plot-git-ops.dat
gnuplot < gnuplot/access-logs/generate-git-ops-plot.plot

time ./bin/logparser gitDurations ${LOG_FILE} +RTS -sstderr > clone-duration.dat
gnuplot < gnuplot/access-logs/generate-git-durations.plot

time ./bin/logparser maxConn ${LOG_FILE} +RTS -sstderr > plot-all.dat
gnuplot < gnuplot/access-logs/generate-max-conn-plot.plot

time ./bin/logparser protocolStats ${LOG_FILE} +RTS -sstderr > protocol-stats.dat
gnuplot < gnuplot/access-logs/generate-git-protocol.plot

time ./bin/logparser repositoryStats ${LOG_FILE} +RTS -sstderr > repository-stats.dat
gnuplot < gnuplot/access-logs/repository-stats.plot
