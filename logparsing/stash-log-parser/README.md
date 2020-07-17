# Atlassian Stash and Bitbucket Server access log parser


The log parser parses and aggregates the access logs of the Atlassian
Stash/Bitbucket Server web application. The main focus is on analyzing 
the git operations as they tend to dominate the overall performance of the application.

## Installation

### Prerequisites
_Before you start, please make sure you have [XQuartz](http://xquartz.macosforge.org/landing/) installed._

### Download Binaries

There are pre-built binaries for Mac OS X and Linux that can be downloaded from:

[https://bitbucket.org/atlassianlabs/stash-log-parser/downloads/](https://bitbucket.org/atlassianlabs/stash-log-parser/downloads/)

## Usage

The `logparser` binary supports multiple commands and accepts one or more
logfiles as arguments (either in uncompressed or compressed (bzip2) form).

Executing `logparser` without any arguments or with the `--help` argument will
show the help with a list of supported commands:

    $ logparser --help
    logparser 3.0

    logparser [COMMAND] ... [OPTIONS]
      Logparser for the Atlassian Stash/Bitbucket Server access logs

    Commands:
      maxConn                Show the maximum number of concurrent requests per
                             hour
      ...


The logparser will parse, analyze and aggregate the log files. It can either print the
aggregated records to STDOUT or it can generate graphs that show the aggregated results.

### Log aggregation

E.g. for the `gitOperations` command that shows the number of git operations
per hour, the output will look like this:


    [922] λ > logparser gitOperations atlassian-stash-access-2012-*.log.bz2
    # Date | clone | fetch | shallow clone | push | ref advertisement ...
    2012-08-22 18|2|0|13|0|733|0|0|0|0|0|2|0|13|0|733
    2012-08-22 19|3|24|74|0|1660|0|0|0|0|0|3|24|74|0|1660
    2012-08-22 20|2|33|119|0|1369|0|0|0|0|0|2|33|119|0|1369
    2012-08-22 21|1|12|49|0|1514|0|0|0|0|0|1|12|49|0|1514

The fields are `|` separated. The first column usually contains a date field
(using a 60 minute granularity). The format of the remaining columns depends on
the command that is being used.

The first line of the output is a column name header prepended by a '#'.

The output can be used to further analyze the results.

### Chart generation

Most commands accept a `--graph` or `-g` flag that will switch the logparser from printing aggregate results to STDOUT to generating graphs that will be stored in the current working directory (or in the directory specified in the `--target` argument).

Access log format
=================

The access log format is documented here:
[How to read the Bitbucket Server Log Formats](https://confluence.atlassian.com/display/BitbucketServerKB/How+to+read+the+Bitbucket+Server+Log+Formats)