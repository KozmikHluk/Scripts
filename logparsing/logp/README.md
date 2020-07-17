# README #
Author: Craig Drummond
Last Revision Date: 06/28/2017
Current Version: 2.3.6

*Note* to use this script with Stash 3.x logs you must pass the -s option on the command line

# This project is being renamed.  Action on your part may be required #
Starting with version 2.3.6, the main script will change from lp.sh to logp.sh due to issue #12.  When this happens this repository will be renamed as well to be logp.  You will need to update your remote settings if you are pulling the latest updates directly from this repository

I am targeting June 28, 2017, for the release of this renamed script \ repository

########################################################################################
## Version History ##
2.3.6 - Fixed issue #11 and #12 (incorrect Ref Advertisement count and renaming lp.sh to logp.sh)

2.3.5 - Fixed issue #9 (clone count not correctly counting SSH and HTTP(S) clones

2.3.4 - Fixed issue #8 (clone count displaying scm/project instead of project/repo)
        Pull request #5, fixing the missing numeric sort in find_clone_ips

2.3.3 - Fixed the problem with sed errors displaying on the screen

2.3.2 - Made Bitbucket the default log file format.  Now you need to pass a -s if you want to analyze Stash Access logs
         Fixed issue where Datacenter ref advertisements would be counted twice (added an additional exclusion when searching for refs)
         Fixed issue where Refs were being double counted because the exclusion was incorrect
         Fixed the display of numbers to include a thousand's separator if the number if over 999

2.1 - Added the ability to change to Bitbucket Server 4.x logs by passing the -b option
      on the command line

2.0 - Modified the output to the screen to make it easier to copy and paste the report
      into Jira

1.1 - Fixed several spelling errors in the output, resolved double counting of some 
      HTTP(s) and implicit SSH ref advertisement requests

1.0 - Initial Version
#######################################################################################

### What is this repository for? ###
* logp.sh
* This shell script automates the parsing of Atlassian Bitbucket or Stash Access Logs and reports where clone, push, fetch, and ref advertisement traffic is originating from

## Version 2.3.5 ##

### How do I get set up? ###
**Summary of set up**
* Copy logp.sh to a location in your path

**Configuration**

* none

**Dependencies**

* Standard Unix/Linux/OSX commands, grep, awk, sed, etc

**Usage**

* `logp.sh <COMMAND> <PATH> <OPTIONS> <OVERRIDE>`

**Database configuration**

* N/A

**Deployment instructions**

* N/A

### Who do I talk to? ###

* Issues can be logged at [lp Issues](https://bitbucket.org/cdrummond/logp/issues)

# Full Usage Guide #
-----------------------
## Bitbucket (and Stash) Log Parser - version 2.3.x ##

One of the best tools available for understanding the activity and performance of Bitbucket\Stash is the publicly available [logparser](https://bitbucket.org/ssaasen/stash-log-parser)

This tool is exceptional at providing graphs that show how many clones, pushes, fetches, and ref advertisements happened during an hour, day, or week.  The logparser can identify the top 10 repositories that were cloned and log-parser can identify the server time for these activities.

However, this tool lacks the ability to identify *where* the traffic originated from.  It is one thing to understand that the logs show a large number of ref advertisements but it is a very different thing identifying where those requests came from.

Introducing logp.sh.  This Bitbucket\Stash log parser will generate several different types of reports that help to identify who/what is generating the traffic.  logp.sh is a bash shell script that analyzes Bitbucket or Stash access logs.  This document describes how to install and use the script.  logp.sh will work on Linux and OSX systems.  No testing has been done to use the script on MS Windows based systems.

## Installation ##
### Clone the script ###
* Clone the source from the repository on Bitbucket `git clone https://bitbucket.org/cdrummond/logp.git`

* Copy logp.sh to a location that is in your path (or add the current location to your path)

### Usage ###
`logp.sh <COMMAND> <PATH> <OPTIONS> <OVERRIDE>`

#### <COMMAND> - REQUIRED ####

**-version** - Prints out the current version of the script and exits.  When using this <COMMAND> you can leave off all of the other options

**ALL** - Run all the reports below

**REF** - Generates a list of all Ref Advertisements from HTTP(s) and SSH sources. This option is a dependency of REFIP and REPO commands. The final report will be found in <PATH> and will be titled `all_refs.rpt`

**REFIP** - Generates a list of IP addresses that have generated Ref Advertisements.  The list is reverse sorted with the IP addresses with the most requests at the top.  On the screen, the top 20 IP addresses and their number will be printed.  The final report will be found in <PATH> and will be titled `ref_ips_final.rpt`
			
**CLONEIP** - Generates a list of IP addresses that have performed clones.  The list is reverse sorted with the IP addresses with the most requests at the top.  On the screen, the top 20 IP addresses and their number will be printed.  The final report will be found in <PATH> and will be titled `clone_ips_final.rpt`
			
**PUSHIP** - Generates a list of IP addresses that have performed pushes.  The list is reverse sorted with the IP addresses with the most requests at the top. On the screen, the top 20 IP addresses and their number will be printed.  The final report will be found in <PATH> and will be titled `push_ips_final.rpt`
		
**FETCHIP** - Generates a list of IP addresses that have performed fetches.  The list is reverse sorted with the IP addresses with the most requests at the top.  On the screen, the top 20 IP addresses and their number will be printed.  The final report will be found in <PATH> and will be titled `fetch_ips_final.rpt`
			
**REPO** - Generates a list of repositories and the number of Ref Advertisement requests it has received. The list is reverse sorted with the repositories with the most Ref Advertisements at the top. On the screen, the top 20 repositories and the number of Ref Advertisements will be printed.  The final report will be found in <PATH> and will be titled `finalrepos.rpt`

**CLONES** - Generates a list of repositories and the number of times those repositories have been cloned.  This list is reverse sorted with the repositories with the most clones at the top.  On the screen, the top 20 repositories and the number of times they have been cloned will be printed.  The final report will be found in <PATH> and will be titled 'clone_count.rpt'

#### <PATH> - REQUIRED ####
This must be a valid path, the user must have read\write access to the directory. The files created during the process will be stored in this location when the script is complete.

If the logp.sh script is in your path it can be run from any location. The script will leave you in the directory that you executed it from, but it will do all the work it needs to do in the location specified in this parameter

##### Examples #####
`logp.sh ALL /opt/Atlassian/application-data/stash/log`
* This example would generate all reports in the specified directory

`logp.sh ALL .`
* This example would generate all the reports in the current directory

#### <OPTIONS> - OPTIONAL (unless <OVERRIDE> is to be specified) ####

-s - Change the defualt file type to analyze from atlassian-bitbucket-access*.log to atlassian-stash-access*.log

-d - Places the script in Debug mode which prints details to the screen while the script is running

-r - By default logp.sh will abort if previous .rpt files exist in the <PATH>.  -r allows for previously created .rpt files to be overwritten.

\-  \- When you do not want to be in debug mode and you don't want to overwrite previous files but you do want to override the default files to be evaluated you must include a '-' as the option

##### Examples #####
`logp.sh ALL /opt/Atlassian/application-data/stash/log -s`
* This example would generate all reports in the specified directory, but would analyze atlassian-stash-access*.logs instead of the default atlassian-bitbucket-access*.log files

`logp.sh ALL /opt/Atlassian/application-data/bitbucket/log -d`
* This example would generate all reports in the specified directory, with debug data written to the screen

`logp.sh ALL /opt/Atlassian/application-data/bitbucket/log -r`
* This example would generate all reports in the specified directory, overwriting any existing .rpt files rather than aborting

`logp.sh ALL /opt/Atlassian/application-data/bitbucket/log -dr`
* This example would generate all reports in the specified directory, overwriting any existing .rpt files rather than aborting and with debug data written to the screen

`logp.sh ALL /opt/Atlassian/application-data/stash/log -sdr`
* This example would generate all reports in the specified directory, analyzing atlassian-stash-access*.logs, overwriting any existing .rpt files rather than aborting, and with debug data written to the screen

`logp.sh ALL /opt/Atlassian/application-data/bitbucket/log - atlassian-bitbucket-access-2015-06-07*.log`
* This example would generate all reports in the specified directory but would only evaluate access logs for June 7, 2015

#### <OVERRIDE> - OPTIONAL ####
By default logp.sh will analyze the atlassian-bitbucket-access*.log files (or atlassian-stash-access*.log files if the -s option is used) in the <PATH>.  
Sometimes you may want to analyze only certain logs files (to analyze a single day or just the most recent log).  To override the defaults you must provide an <OPTION>.  

##### Examples #####
`logp.sh ALL /opt/Atlassian/application-data/bitbucket/log - atlassian-bitbucket-access.log`
*  This example would generate all reports in the specified directory only analyze the single file atlassian-bitbucket-access.log


### Limitations ###
* logp.sh has been tested on access logs from Stash 2.6.x, 3.6.x, 3.7.x, 3.9.x., 3.10.x, 3.11.x, & 4.0.x - 4.14.6  It is anticipated that the script will continue to work for future versions of Bitbucket, unless the access log format changes. If that happens the script will need to be retested and any problems resolved

* logp.sh is only tested on OSX and Linux shell.  It is possible to get *nix tools (awk, grep, sed, sort, etc) to work on a Windows system but there has been no testing of this.

* logp.sh requires that if there are load balancers or proxies being used, they must forward the originating IP address to Bitbucket\Stash.  Please see https://confluence.atlassian.com/bitbucketserverkb/log-the-original-ip-address-when-bitbucket-server-is-behind-a-load-balancer-779171715.html