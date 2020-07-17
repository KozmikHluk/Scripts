#!/bin/bash
#################################################
##
## Title:  Bitbucket Log Information 
##
## Description: This script analyzes the access logs with the focus on understanding "where" 
##              requests are coming from and which repositories are having the most 
##              ref advertisements and the most clones
##
##              This script is dependent on the load balancer or reverse proxy (if used) providing
##              Bitbucket with the original IP address.  If you are seeing very few distinct IP
##              addresses please review:
##              https://confluence.atlassian.com/stashkb/log-the-original-ip-address-when-stash-is-behind-a-load-balancer-652443962.html 
##
## Author: Craig Drummond
##
## Last Mode Date: 06/28/2017
##
#################################################
## 
## Revision History:
##
## 0.0.1 > 06/04/15 Bash command line to be converted to Shell Script
## 1.0.0 > 06/10/15 Initial Version Released
## 1.0.1 > 06/10/15 Fixed README.md
## 1.0.2 > 06/10/15 Fixed README.md
## 1.0.3 > 06/10/15 Removed README.MD, Updated README.md
## 1.1.0 > 08/27/15 Fixed problem with some HTTP(s) requests being double counted
## 2.0.0 > 09/29/15 Modified the output to be easily copied and pasted into Jira Issues
## 2.1.0 > 12/15/15 Updated the script to handle atlassian-bitbucket-access logs by passing the -b option
## 2.3.0 > 11/18/16 Converted script to analyze Bitbucket Access logs by default.  
##                  Fixed bugs with Ref Adv. count
##                  Fixed bug with Data Center double counting Refs
##                  Converted all of the display numbers to support adding the thousands separator  
## 2.3.1 > 11/18/16 Fixed Readme
## 2.3.2 > 11/18/16 Fixed Readme
## 2.3.3 > 11/18/16 Fixed sed issues with information displayed on the screen
## 2.3.4 > 01/31/17 Fixed issue #8 (clone count displaying scm/project instead of project/repo)
##                  Pull request #5, fixing the missing numeric sort in find_clone_ips
## 2.3.5 > 02/24/17 Fixed issue #9 (clone count not correctly counting SSH and HTTP(S) clones
## 2.3.6 > 06/28/17 Fixed issue #11, Ref Advertisement count was off because it was counting all internal 
##                  requests as being a Ref Advertisement.
##		    Fixed issue #12, renamed the main script (lp.sh) to logp.sh because lp is an internal
##		    command on linux that would send the contents of the access logs you are trying to
##		    analyze to the printer
##
################################################# 
##
## Usage:
##
## logp.sh <command> <path> <options> <override>
## 
##    Commands:
##         -version - Print out the version of the script you are running
##         ALL      - Runs All the reports below
##         REF      - Get the total number Ref Advertisments
##         REFIP    - Get a list of the top 20 IP addresses and the number of Ref Advertisements they have done
##         REPO     - Get a list of reposiories and the number of ref advertisements that were made against it 
##         CLONEIP  - Get a list of the top 20 IP addresses that performed clones
##         PUSHIP   - Get a list of the top 20 IP addresses that performed pushes
##         FETCHIP  - Get a list of the top 20 IP addresses that performed fetches
##         CLONES   - Get a list of the tip 20 Repos and the number of timees they were cloned
##    Options:
##         -s - Analyze Stash Access logs instead of Bitbucket Access Logs
##         -d - Debug Mode
##         -r - overwrite existing reports
##    Override:
##         <file(s) to evaluate>
##
#################################################

#################################################
# Global Variables
#################################################
VERSION="2.3.6"

declare -a filenames=(start-http_refs.txt 
          start-explicit_ssh_refs.txt 
          start-implicit_ssh_refs.txt
					http_repos.txt 
          http_repos.fin 
					ssh_implicit_repos.txt 
          ssh_implicit_repos.fin
					ssh_explicit_repos.txt 
          ssh_explicit_repos.fin
					repos.txt 
          sortedrepos.out 
          reducedrepos.out 
          sortedrepos.fin
					clone_sorted.out 
          clone_reduced.out 
          clone_sorted.fin
					push_sorted.out 
          push_reduced.out 
          push_sorted.fin
					fetch_sorted.out 
          fetch_reduced.out 
          fetch_sorted.fin
					http_ref_ips.txt 
          ssh_exp_ref_ips.txt 
          ssh_imp_ref_ips.txt
					all_ref_ips.txt 
          all_ref_ips.out 
          all_ref_ips.fin)

declare -a finalnames=(allrefs.rpt ref_ips_final.rpt clone_ips_final.rpt push_ips_final.rpt fetch_ips_final.rpt finalrepos.rpt clone_count.rpt)
FILESTOSCAN="atlassian-bitbucket-access*.log"
DEBUG="N"
ABORT="N"
OVERWRITE="N"
STEP=1
#################################################

##################################################################################################
## FUNCTIONS
##################################################################################################

#################################################
# function cleanup
#
# Mod Date: 6/9/2015 - cd
# Description: Cleans up the files created during the execution of the script. 
# Dependencies: 
#    Functions: fremove, writemsg
#    variables: filenames (global)
#################################################
function cleanup() {
  writemsg "Made it to cleanup"
  for element in ${filenames[*]};
  do
    #echo "Not removing $element"
    fremove $element
  done
}

#################################################
# function initme
#
# Mod Date: 6/9/2015 - cd
# Description: Prepares for running, verifys if previous runs exist 
# Dependencies: 
#    Functions: fexist, writemsg
#    variables: finalnames (global), ABORT (global)
#################################################
function initme() {
	writemsg "Made it to initme"

	for element in ${finalnames[*]};
    do
      if [ "$ABORT" = "N" ]; then 
      	writemsg "checking for $element"
        fexist $element
      fi
    done
}

#################################################
# function fremove
#
# Mod Date: 6/9/2015 - cd
# Description: removes files if they exist 
# Dependencies: 
#    Functions: 
#    variables: $1 (local)
#################################################
function fremove() {
	if test -f "$1"; then 
		writemsg "$1"
    rm "$1"
    fi
}

#################################################
# function fexist
#
# Mod Date: 6/9/2015 - cd
# Description: If overwriting then remove the passed file, otherwise check if the passed file exists and abort if it does 
# Dependencies: 
#    Functions: fremove
#    variables: OVERWRITE (global), $1 (local), ABORT (global)
#################################################
function fexist() {
	if [ "$OVERWRITE" = "N" ]; then
		if test -f "$1"; then
			echo "$1 Exists, please rename this file and try again or pass the -r option to enable overwrite"
			ABORT="Y"
		fi
	else
		fremove "$1"
	fi
}

#################################################
# function pause
#
# Mod Date: 6/9/2015 - cd
# Description: used only in debugging. 
# Dependencies: 
# Functions: 
# variables: 
#################################################
function pause() {
   read -p "$*"
}

#################################################
# function clrscr
#
# Mod Date: 6/9/2015 - cd
# Description: Clears the screen. 
# Dependencies: 
# Functions: 
# variables: 
#################################################
function clrscr() {
  clear
}

#################################################
# function writemsg
#
# Mod Date: 6/9/2015 - cd
# Description: When in debug mode write the passed message to the screen
# Dependencies: 
# Functions: 
# variables: DEBUG (global)
#################################################
function writemsg() {
  if [ "$DEBUG" = "Y" ]; then
  	echo "$*"
  fi
}

#################################################
# function writestepmsg
#
# Mod Date: 6/9/2015 - cd
# Description: calls writemsg and increments STEP. 
# Dependencies: 
# Functions: writemsg
# variables: STEP (global)
#################################################
function writestepmsg() {
	writemsg "Step $STEP..."
	let STEP+=1
}

#################################################
# function chdir
#
# Mod Date: 6/9/2015 - cd
# Description: change to the passed directory
# Dependencies: 
# Functions: writemsg
# variables: 
#################################################
function chdir() {
  cd "$*"
  writemsg "$PWD"
} 

#################################################
# function find_refs
#
# Mod Date: 6/9/2015 - cd
# Description: Parses Access Logs for Ref Advertisements
# Dependencies:  
# Functions: writemsg, writestepmsg
# variables: 
#################################################
function find_refs() {
	writemsg "Made it to Ref"
	echo "{panel:title=Total Ref Advertisements}"
	writemsg "Files to Scan: $FILESTOSCAN"
	writestepmsg
        
  # Find HTTP\S ref advertisements but make sure I only count the outputs, ignore the inputs
  # 11/18/2016 cd : Fixed the incorrect @i that was causing double counts and added exclusion of i\* to account for Data Center

	grep -H "o[@*]" $FILESTOSCAN | grep "git/info/refs" > start-http_refs.txt
	writestepmsg

  # The next step is to build the SSH ref advertisements by looking for explicitly known refs as well
  # as refs that implicit because they have no other type.

  grep -H "o[@*]" $FILESTOSCAN | grep "refs," > start-explicit_ssh_refs.txt
	writestepmsg
	
  grep -H "o[@*]" $FILESTOSCAN | grep "| ssh |" | grep "git[/\'\"]" | grep -v "clone[ ,]\|fetch[ ,]\|push[ ,]\|refs[ ,]\|negotiation[ ,]"  > start-implicit_ssh_refs.txt
	writestepmsg
      
  # Combine all the files into one allrefs.rpt file.
  # 11/18/2016 cd : removed the allrefs.rpt from being displayed on the screen

	cat start-*.txt > allrefs.rpt
	writestepmsg
	printf "Number of refs: %'d\n" $(grep " " allrefs.rpt | wc -l)

	writemsg "File allrefs.rpt is complete."
    echo "{panel}"
    echo " "
}

#################################################
# function find_ref_ips
#
# Mod Date: 6/9/2015 - cd
# Description: Compile a reverse order list of IP Addresses that have made Ref Advertisements. 
# Dependencies: 
# Functions: find_refs, writemsg, writestepmsg
# variables: 
#################################################
function find_ref_ips() {
	writemsg "Made it to find_ref_ips"
	if [ ! -f "start-http_refs.txt" ]; then find_refs; fi
    if [ ! -f "start-explicit_ssh_refs.txt" ]; then find_refs; fi
    if [ ! -f "start-implicit_ssh_refs.txt" ]; then find_refs; fi
    echo "{panel:title=Top 20 Ref Advertisement IP Addresses}"
    writestepmsg

    # Extract IPs from start-http_refs.txt
    awk -F '|' '{ print $1 }' start-http_refs.txt | awk -F ':' '{ print $2 }' | awk -F ',' '{ print $1 }' > http_ref_ips.txt

    writestepmsg

    # Extract IPs from start-explicit_ssh_refs.txt
    awk -F '|' '{ print $1 }' start-explicit_ssh_refs.txt | awk -F ':' '{ print $2 }' > ssh_exp_ref_ips.txt

    writestepmsg

    # Extract IPs from start-implicit_ssh_refs.txt
    awk -F '|' '{ print $1 }' start-implicit_ssh_refs.txt | awk -F ':' '{ print $2 }' > ssh_imp_ref_ips.txt

    writestepmsg
    # combine & sort all three files from previous three steps
    cat *_ref_ips.txt | sort -n > all_ref_ips.txt

    writestepmsg

    # Get all the Unique IPS and their counts
    uniq -c all_ref_ips.txt all_ref_ips.out 

    writestepmsg
    # Sort in reverse order the count
    sort -n -r all_ref_ips.out > all_ref_ips.fin

    writestepmsg

    # format the final report
    awk '{printf "%s : %'\''d\n", $2, $1 }' all_ref_ips.fin > ref_ips_final.rpt

    writestepmsg
    head -20 ref_ips_final.rpt
    echo "{panel}"
    echo " "
}

#################################################
# function find_clone_ips
#
# Mod Date: 6/9/2015 - cd
# Description: Compile a reverse order list of IP addresses that have made clone requests 
# Dependencies: 
# Functions: writemsg, writestepmsg
# variables: 
#################################################
function find_clone_ips() {
	writemsg "Made it to find_clone_ips"
	echo "{panel:title=Top 20 Clone IP Addresses}"  
	writestepmsg
	grep -H "git-upload-pack" $FILESTOSCAN | grep " clone" | awk -F ':' '{print $2}' | awk -F ',' '{print $1}' | awk '{print $1}' | sort -n > clone_sorted.out 
	writestepmsg
	uniq -c clone_sorted.out clone_reduced.out 
	writestepmsg
	sort -n -r clone_reduced.out > clone_sorted.fin
	writestepmsg
	awk '{printf "%s : %'\''d\n", $2, $1 }' clone_sorted.fin > clone_ips_final.rpt   
	head -20 clone_ips_final.rpt
    echo "{panel}"
    echo " "
}

#################################################
# function find_push_ips
#
# Mod Date: 6/9/2015 - cd
# Description: Compile a reverse order list of IP addresses that have made push requests
# Dependencies: 
# Functions: writemsg, writestepmsg
# variables: 
#################################################
function find_push_ips() {
	writemsg "Made it to find_push_ips"
	echo "{panel:title=Top 20 Push IP Addresses}"  
	writestepmsg
	grep -H "git-receive-pack" $FILESTOSCAN | grep " push" | awk -F ':' '{print $2}' | awk -F ',' '{print $1}' | awk '{print $1}' | sort -n > push_sorted.out 
	writestepmsg
	uniq -c push_sorted.out push_reduced.out 
	writestepmsg
	sort -n -r push_reduced.out > push_sorted.fin
	writestepmsg
	awk '{printf "%s : %'\''d\n", $2, $1 }' push_sorted.fin > push_ips_final.rpt   
	head -20 push_ips_final.rpt
	echo "{panel}"
    echo " "
}

#################################################
# function find_fetch_ips
#
# Mod Date: 6/9/2015 - cd
# Description: Compile a reverse order list of IP addresses that have made fetch requests
# Dependencies: 
# Functions: writemsg, writestepmsg
# variables: 
#################################################
function find_fetch_ips() {
	writemsg "Made it to find_fetch_ips"
	echo "{panel:title=Top 20 Fetch IP Addresses}"
	writestepmsg  
	grep -H "git-upload-pack" $FILESTOSCAN | grep " fetch" | awk -F ':' '{print $2}' | awk -F ',' '{print $1}' | awk '{print $1}' | sort -n > fetch_sorted.out
	writestepmsg 
	uniq -c fetch_sorted.out fetch_reduced.out
	writestepmsg 
	sort -n -r fetch_reduced.out > fetch_sorted.fin
	writestepmsg
	awk '{printf "%s : %'\''d\n", $2, $1 }' fetch_sorted.fin > fetch_ips_final.rpt   
	head -20 fetch_ips_final.rpt
	echo "{panel}"
    echo " "
}

#################################################
# function find_repos
#
# Mod Date: 6/9/2015 - cd
# Description: Compile a reverse order list of Repositories that have Ref Advertisement requests 
# Dependencies: 
# Functions: 
# variables: 
#################################################
function find_repos() {
	writemsg "Made it to Repo"
	echo "{panel:title=Number of Ref Advertisements per Repository}"
    if [ ! -f "start-http_refs.txt" ]; then find_refs; fi
    if [ ! -f "start-explicit_ssh_refs.txt" ]; then find_refs; fi
    if [ ! -f "start-implicit_ssh_refs.txt" ]; then find_refs; fi
    writemsg "Start Getting Repositories..."
    writestepmsg
    awk -F '|' '{ print $6 }' start-http_refs.txt > http_repos.txt
    writestepmsg
    awk -F '/' '{ print $3"/"$4 }' http_repos.txt > http_repos.fin
    writestepmsg
    awk -F '|' '{ print $6 }' start-implicit_ssh_refs.txt > ssh_implicit_repos.txt
    writestepmsg
    sed -i  -e 's|~|\/~|g' ssh_implicit_repos.txt
    writestepmsg
    awk -F '/' '{ print $2"/"$3 }' ssh_implicit_repos.txt > ssh_implicit_repos.fin
    writestepmsg
    sed -i  -e 's|['\'']||g' ssh_implicit_repos.fin
    writestepmsg
    awk -F '|' '{ print $6 }' start-explicit_ssh_refs.txt > ssh_explicit_repos.txt
    writestepmsg
    sed -i -e 's|~|/~|g' ssh_explicit_repos.txt
    writestepmsg
    awk -F '/' '{ print $2"/"$3 }' ssh_explicit_repos.txt > ssh_explicit_repos.fin
    writestepmsg
    sed -i  -e 's|['\'']||g' ssh_explicit_repos.fin
    writestepmsg
    cat *repos.fin > repos.txt
    writestepmsg
    sort -n repos.txt > sortedrepos.out
    writestepmsg
    uniq -c sortedrepos.out reducedrepos.out
    writestepmsg
    sort -n -r reducedrepos.out > sortedrepos.fin
    writestepmsg
    awk '{printf "%'\''d - %s\n", $1, $2 }' sortedrepos.fin > finalrepos.rpt
    head -20 finalrepos.rpt
    echo "{panel}"
    echo " "
}

#################################################
# function find_repos
#
# Mod Date: 6/9/2015 - cd
# Description: Compile a reverse order list of Repositories that have Ref Advertisement requests 
# Dependencies: 
# Functions: 
# variables: 
#################################################
function find_clones() {
  writemsg "Made it to Clones"
  echo "{panel:title=Number of Clones per Repository}"
    writestepmsg
    echo "h4. HTTP(s) clones:"
    grep -h "git-upload-pack" $FILESTOSCAN | grep ", clone" | grep -v "SSH" | awk -F '|' '{ print $6 }' | awk -F ' ' '{ print $2 }' | awk -F '/' '{ print $3"/"$4 }' | sed "s/'//" | sort | uniq -c | sort -n -r | awk '{printf "%'\''d - %s\n", $1, $2 }' > clone_count.rpt
    writestepmsg
    head -20 clone_count.rpt
    echo "h4. SSH Clones:"
    grep -h "git-upload-pack" $FILESTOSCAN | grep ", clone" | grep "SSH" | awk -F '|' '{ print $6 }' | awk -F ' ' '{ print $4 }' | awk -F '/' '{ print $2"/"$3 }' | sed "s/'//" | sort | uniq -c | sort -n -r | awk '{printf "%'\''d - %s\n", $1, $2 }' > clone_count.rpt
    writestepmsg
    head -20 clone_count.rpt
  echo "{panel}"
  echo " "
}

#################################################
# function lpf
#
# Mod Date: 6/9/2015 - cd
# Description: This is the main function for this script.  
# Dependencies: 
# Functions: 
# variables: 
#################################################
function lpf {
  clrscr
  date # Print the start date and time to the screen

  # Evaluate the command line for correct usage
  case "$1" in
    "") echo "Usage: logp.sh <command> <path> <options> <override>"
        echo "$VERSION"
        ABORT="Y"
        return 98;;
    "-version") echo "Version: $VERSION"
        ABORT="Y"
        return 0;;
    * ) case "$2" in 
          "") echo "Usage logp.sh <command> <path> <options> <override>"
              ABORT="Y"
              return 99;;
          * ) OCOMMAND=$1
              COMMAND=`echo "$OCOMMAND" | tr '[a-z]' '[A-Z]'`
              DPATH=$2
              case "$3" in
                "-s" ) FILESTOSCAN="atlassian-stash-access*.log";;
                "-d" ) DEBUG="Y";;
 				        "-r" ) OVERWRITE="Y";;
                "-sd" | "-ds" ) FILESTOSCAN="atlassian-stash-access*.log"
                  DEBUG="Y";;
                "-sr" | "-rs" ) FILESTOSCAN="atlassian-stash-access*.log"
                  OVERWRITE="Y";;
                "-dr" | "-rd" ) 
                  DEBUG="Y"
							    OVERWRITE="Y";;
                "-srd" | "-sdr" | "-rsd" | "-rds" | "drs" | "-dsr" ) FILESTOSCAN="atlassian-stash-access*.log"
                  DEBUG="Y"
                  OVERWRITE="Y";;
					   	  * ) if [ "$DEBUG" = "Y" ]; then 
									    echo "no options pased" 
								    fi
								    OPTION="";;
              esac
              case "$4" in
              	"" ) writemsg "No overrides passed";;
                 * ) FILESTOSCAN=$4;;
              esac  
        esac
  esac

  # Command line parsing is complete, perform the tasks requested if everything is valid
  if [ "$ABORT" = "N" ]; then
    # Check if Path Exists
    if [ -d "$DPATH" ]; then
      writemsg "Path Exists"
      startpath="$PWD"
      chdir "$DPATH"
      initme
    else
	   echo "Path Does not Exist"
	   echo "Please enter a valid path"
	   ABORT="Y"
	   return 97; 	
	  fi
  fi

  # The path exists so we can check for the existence of atlassian-bitbucket-access*.log files
  if [ "$ABORT" = "N" ]; then
	  for f in $FILESTOSCAN; do
      writemsg "$f"
    	[ -e "$f" ] && writemsg "Log files exist, continuing on" || ABORT="Y"

    	## This is all we needed to know, so we can break after the first iteration
    	break
	  done
  fi
  
  # The file(s) exist so we can do the requested checks
  if [ "$ABORT" = "N" ]; then
    writemsg $FILESTOSCAN	  	
    case  "$COMMAND" in
	        "ALL" ) writemsg "Made it to All"
			find_refs
			find_ref_ips
			find_clone_ips
			find_push_ips
			find_fetch_ips
			find_repos
            		find_clones;;
	        "REF" ) find_refs;;
       	      "REFIP" ) find_ref_ips;;
	    "CLONEIP" ) find_clone_ips;;
       	     "PUSHIP" ) find_push_ips;;
            "FETCHIP" ) find_fetch_ips;;
	       "REPO" ) find_repos;;
             "CLONES" ) find_clones;;
	            * ) echo "Valid commands are:"
	                echo "      ALL, REF, REFIP, CLONEIP, PUSHIP, FETCHIP, REPO, CLONES"
	                ABORT="Y";;
	  esac

  	# Remove any files created in the process
  	cleanup  
  else
  	echo "Abort was called"
  fi

  # Change back to the directory you were in when you launched the script
  chdir "$startpath"

  # Write the end date and time to the screen so you can determine how long the script took 
  # in case you don't have a Linux shell that tells you how long the last command took.
  date
}

#################################################
lpf "$@"
