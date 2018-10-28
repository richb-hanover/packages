#!/bin/sh

# betterspeedtest.sh - Script to simulate http://speedtest.net
# Start pinging, then initiate a download, let it finish, then start an upload
# Output the measured transfer rates and the resulting ping latency
# It's better than 'speedtest.net' because it measures latency *while* measuring the speed.

# Usage: sh betterspeedtest.sh [-4 -6] [ -H netperf-server ] [ -t duration ] [ -p host-to-ping ] [ -n simultaneous-streams ]

# Options: If options are present:
#
# -H | --host:   DNS or Address of a netperf server (default - netperf.bufferbloat.net)
#                Alternate servers are netperf-east (east coast US), netperf-west (California), 
#                and netperf-eu (Denmark)
# -4 | -6:       enable ipv4 or ipv6 testing (ipv4 is the default)
# -t | --time:   Duration for how long each direction's test should run - (default - 60 seconds)
# -p | --ping:   Host to ping to measure latency (default - gstatic.com)
# -n | --number: Number of simultaneous sessions (default - 5 sessions)

# Copyright (c) 2014 - Rich Brown rich.brown@blueberryhillsoftware.com
# GPLv2

# Summarize the contents of the ping's output file to show min, avg, median, max, etc.
#   input parameter ($1) file contains the output of the ping command

summarize_pings() {     
  
  # Process the ping times, and summarize the results
  # grep to keep lines that have "time=", then sed to isolate the time stamps, and sort them
  # awk builds an array of those values, and prints first & last (which are min, max) 
  # and computes average.
  # If the number of samples is >= 10, also computes median, and 10th and 90th percentile readings
  sed 's/^.*time=\([^ ]*\) ms/\1/' < $1 | grep -v "PING" | sort -n | \
  awk 'BEGIN {numdrops=0; numrows=0;} \
    { \
      if ( $0 ~ /timeout/ ) { \
          numdrops += 1; \
      } else { \
        numrows += 1; \
        arr[numrows]=$1; sum+=$1; \
      } \
    } \
    END { \
      pc10="-"; pc90="-"; med="-"; \
      if (numrows == 0) {numrows=1} \
      if (numrows>=10) \
      {   ix=int(numrows/10); pc10=arr[ix]; ix=int(numrows*9/10);pc90=arr[ix]; \
        if (numrows%2==1) med=arr[(numrows+1)/2]; else med=(arr[numrows/2]); \
      }; \
      pktloss = numdrops/(numdrops+numrows) * 100; \
      printf("  Latency: (in msec, %d pings, %4.2f%% packet loss)\n      Min: %4.3f \n    10pct: %4.3f \n   Median: %4.3f \n      Avg: %4.3f \n    90pct: %4.3f \n      Max: %4.3f\n", numrows, pktloss, arr[1], pc10, med, sum/numrows, pc90, arr[numrows] )\
     }'
}

# Summarize the contents of the load file to show mean, stddev CPU utilization.
#   input parameter ($1) file contains CPU load samples from /proc/stat

summarize_load() {

  < $1 awk '
{
	tot=0
	for (f=2;f<=NF;f++) tot+=$f
	usg = tot - $5
	if (init_tot[$1]=="") {
		init_tot[$1]=tot
		init_usg[$1]=usg
		cpus[num_cpus++]=$1
	}
	if (last_tot[$1]>0) {
		sum_usg_2[$1] += ((usg-last_usg[$1])/(tot-last_tot[$1]))^2
	}
	last_tot[$1]=tot
	last_usg[$1]=usg
}
END {
	num_samp=(NR/num_cpus-1)
	printf("CPU Usage: (%% busy as avg / stddev, %d samples)\n", num_samp)
	for (i=0;i<num_cpus;i++) {
		c=cpus[i]
		if (num_samp>0) {
			avg_usg=(last_usg[c]-init_usg[c])/(last_tot[c]-init_tot[c])
			std_usg=sqrt(sum_usg_2[c]/num_samp-avg_usg^2)
            printf("    %5s: %4.1f%% / %4.1f%%\n", c, avg_usg*100, std_usg*100)
		}
	}
}'
}

# Capture per-CPU load info at 1-second intervals.

sample_load() {
  while : ; do
    sleep 1s
    egrep "^cpu[0-9]+" /proc/stat
  done
}

# Print a line of dots as a progress indicator.

print_dots() {
  while : ; do
    printf "."
    sleep 1s
  done
}

# Stop the current sample_load() process

kill_load() {
  # echo "Load: $load_pid"
  kill -9 $load_pid
  wait $load_pid 2>/dev/null
  load_pid=0
}

# Stop the current print_dots() process

kill_dots() {
  # echo "Pings: $ping_pid Dots: $dots_pid"
  kill -9 $dots_pid
  wait $dots_pid 2>/dev/null
  dots_pid=0
}

# Stop the current ping process

kill_pings() {
  # echo "Pings: $ping_pid Dots: $dots_pid"
  kill -9 $ping_pid 
  wait $ping_pid 2>/dev/null
  ping_pid=0
}

# Stop the current load, pings and dots, and exit
# ping command catches (and handles) first Ctrl-C, so you have to hit it again...
kill_pings_and_dots_and_exit() {
  kill_load
  kill_dots
  echo "\nStopped"
  exit 1
}

# ------------ Measure speed and ping latency for one direction ----------------
#
# Call measure_direction() with single parameter - "Download" or "  Upload"
#   The function gets other info from globals determined from command-line arguments

measure_direction() {

  # Create temp files
  PINGFILE=`mktemp /tmp/measurepings.XXXXXX` || exit 1
  SPEEDFILE=`mktemp /tmp/netperfUL.XXXXXX` || exit 1
  LOADFILE=`mktemp /tmp/measureload.XXXXXX` || exit 1
  DIRECTION=$1

  # Start dots
  print_dots &
  dots_pid=$!
  # echo "Dots PID: $dots_pid"

  # Start Ping
  if [ $TESTPROTO -eq "-4" ]
  then
    ping  $PINGHOST > $PINGFILE &
  else
    ping6 $PINGHOST > $PINGFILE &
  fi
  ping_pid=$!
  # echo "Ping PID: $ping_pid"
  
  # Start CPU load sampling
  sample_load > $LOADFILE &
  load_pid=$!
  # echo "Load PID: $load_pid"

  # Start netperf with the proper direction
  if [ $DIRECTION = "Download" ]; then
    dir="TCP_MAERTS"
  else
    dir="TCP_STREAM"
  fi
  
  # Start $MAXSESSIONS datastreams between netperf client and the netperf server
  # netperf writes the sole output value (in Mbps) to stdout when completed
  for i in $( seq $MAXSESSIONS )
  do
    netperf $TESTPROTO -H $TESTHOST -t $dir -l $TESTDUR -v 0 -P 0 >> $SPEEDFILE &
    # echo "Starting PID $! params: $TESTPROTO -H $TESTHOST -t $dir -l $TESTDUR -v 0 -P 0 >> $SPEEDFILE"
  done
  
  # Wait until each of the background netperf processes completes 
  # echo "Process is $$"
  # echo `pgrep -P $$ netperf `

  for i in `pgrep -P $$ netperf `   # gets a list of PIDs for child processes named 'netperf'
  do
    #echo "Waiting for $i"
    wait $i
  done

  # Print TCP Download speed
  echo ""
  echo " $1: " `awk '{s+=$1} END {print s}' $SPEEDFILE` Mbps

  # When netperf completes, stop the dots and the pings
  kill_load
  kill_pings
  kill_dots

  # Summarize the ping data
  summarize_pings $PINGFILE

  # Summarize the load data
  summarize_load $LOADFILE

  rm $PINGFILE
  rm $SPEEDFILE
  rm $LOADFILE
}

# ------- Start of the main routine --------

# Usage: sh betterspeedtest.sh [ -4 -6 ] [ -H netperf-server ] [ -t duration ] [ -p host-to-ping ] [ -n simultaneous-sessions ]

# “H” and “host” DNS or IP address of the netperf server host (default: netperf.bufferbloat.net)
# “t” and “time” Time to run the test in each direction (default: 60 seconds)
# “p” and “ping” Host to ping for latency measurements (default: gstatic.com)
# "n" and "number" Number of simultaneous upload or download sessions (default: 5 sessions;
#       5 sessions chosen empirically because total didn't increase much after that number)

# set an initial values for defaults
TESTHOST="netperf.bufferbloat.net"
TESTDUR="60"
PINGHOST="gstatic.com"
MAXSESSIONS="5"
TESTPROTO="-4"

# read the options

# extract options and their arguments into variables.
while [ $# -gt 0 ] 
do
    case "$1" in
      -4|-6) TESTPROTO=$1 ; shift 1 ;;
        -H|--host)
            case "$2" in
                "") echo "Missing hostname" ; exit 1 ;;
                *) TESTHOST=$2 ; shift 2 ;;
            esac ;;
        -t|--time) 
          case "$2" in
            "") echo "Missing duration" ; exit 1 ;;
                *) TESTDUR=$2 ; shift 2 ;;
            esac ;;
        -p|--ping)
            case "$2" in
                "") echo "Missing ping host" ; exit 1 ;;
                *) PINGHOST=$2 ; shift 2 ;;
            esac ;;
        -n|--number)
          case "$2" in
            "") echo "Missing number of simultaneous sessions" ; exit 1 ;;
            *) MAXSESSIONS=$2 ; shift 2 ;;
          esac ;;
        --) shift ; break ;;
        *) echo "Usage: sh betterspeedtest.sh [-4 -6] [ -H netperf-server ] [ -t duration ] [ -p host-to-ping ] [ -n simultaneous-sessions ]" ; exit 1 ;;
    esac
done

# Start the main test

if [ $TESTPROTO -eq "-4" ]
then
  PROTO="ipv4"
else
  PROTO="ipv6"
fi
DATE=`date "+%Y-%m-%d %H:%M:%S"`
echo "$DATE Testing against $TESTHOST ($PROTO) with $MAXSESSIONS simultaneous sessions while pinging $PINGHOST ($TESTDUR seconds in each direction)"

# Catch a Ctl-C and stop the pinging and the print_dots
trap kill_pings_and_dots_and_exit HUP INT TERM

measure_direction "Download" 
measure_direction "  Upload" 

