Network Speed Testing
=====================

These scripts were spawned by the CeroWrt project and used to measure network throughput and latency, as part of overall bufferbloat mitigation. They are included here with the permission of the original author, Rich Brown, and include:

* [betterspeedtest.sh](#betterspeedtestsh) - emulate a web-based speed test by downloading and then uploading from an internet server.

* [netperfrunner.sh](#netperfrunnersh) - perform a simultaneous download and upload from an internet server, simulating the FLENT test program.

**Note:** _The test servers and network bandwidth to support these scripts are provided through generous donation and should be used responsibly. Running these scripts to set up and test your SQM configuration or troubleshoot network and latency problems is welcome; however, running a personal "monitoring service" by performing automatic speed tests every 5 minutes for weeks on end would be abusing things. Happy testing!_

---
## [betterspeedtest.sh](https://github.com/openwrt/packages/blob/master/net/speedtest/files/betterspeedtest.sh)

The `betterspeedtest.sh` script emulates the web-based test performed by speedtest.net, but does it one better. While script performs a download and an upload to a server on the Internet, it simultaneously measures latency of pings to see whether the file transfers affect the responsiveness of your network. 

Here's why that's important: If the data transfers do increase the latency/lag much, then other network activity, such as voice or video chat, gaming, and general network activity will also work poorly. Gamers will see this as lagging out when someone else uses the network. Skype and FaceTime will see dropouts or freezes. Latency is bad, and good routers will not allow it to happen.

The betterspeedtest.sh script measures latency during file transfers. To invoke it:

    sh betterspeedtest.sh [ -4 | -6 ] [ -H netperf-server ] [ -t duration ] [ -p host-to-ping ] [-n simultaneous-streams ]

Options, if present, are:

* -H | --host: DNS or Address of a netperf server (default - netperf.bufferbloat.net)  
Alternate servers are netperf-east (east coast US), netperf-west (California), 
and netperf-eu (Denmark)
* -4 | -6:     Enable ipv4 or ipv6 testing (default - ipv4)
* -t | --time: Duration for how long each direction's test should run - (default - 60 seconds)
* -p | --ping: Host to ping to measure latency (default - gstatic.com)
* -n | --number: Number of simultaneous sessions (default - 5 sessions)

The output shows separate (one-way) download and upload speed, along with a summary of latencies, including min, max, average, median, and 10th and 90th percentiles so you can get a sense of the distribution. The tool also displays the percent packet loss. The example below shows two measurements, bad and good. 

On the left is a test run without SQM. Note that the latency gets huge (greater than 5 seconds), meaning that network performance would be terrible for anyone else using the network. 

On the right is a test using SQM: the latency goes up a little (less than 23 msec under load), and network performance remains good.

    Example with NO SQM - BAD                                     Example using SQM - GOOD
    
    root@openwrt:/usr/lib/OpenWrtScripts# sh betterspeedtest.sh   root@openwrt:/usr/lib/OpenWrtScripts# sh betterspeedtest.sh
    [date/time] Testing against netperf.bufferbloat.net (ipv4)    [date/time] Testing against netperf.bufferbloat.net (ipv4)
       with 5 simultaneous sessions while pinging gstatic.com        with 5 simultaneous sessions while pinging gstatic.com
       (60 seconds in each direction)                                (60 seconds in each direction)
    
     Download:  6.65 Mbps                                         Download:  6.62 Mbps
      Latency: (in msec, 58 pings, 0.00% packet loss)              Latency: (in msec, 61 pings, 0.00% packet loss)
          Min: 43.399                                                  Min: 43.092
        10pct: 156.092                                               10pct: 43.916
       Median: 230.921                                              Median: 46.400
          Avg: 248.849                                                 Avg: 46.575
        90pct: 354.738                                               90pct: 48.514
          Max: 385.507                                                 Max: 56.150
    
       Upload:  0.72 Mbps                                           Upload:  0.70 Mbps
      Latency: (in msec, 59 pings, 0.00% packet loss)              Latency: (in msec, 53 pings, 0.00% packet loss)
          Min: 43.699                                                  Min: 43.394
        10pct: 352.521                                               10pct: 44.202
       Median: 4208.574                                             Median: 50.061
          Avg: 3587.534                                                Avg: 50.486
        90pct: 5163.901                                              90pct: 56.061
          Max: 5334.262                                                Max: 69.333

---         
## [netperfrunner.sh](https://github.com/openwrt/packages/blob/master/net/speedtest/files/netperfrunner.sh)

The `netperfrunner.sh` script runs several netperf commands simultaneously.
This mimics the stress test of [netperf-wrapper](https://github.com/tohojo/netperf-wrapper) [Github] but without the nice GUI result.

When you start this script, it concurrently uploads and downloads several
streams (files) to a server on the Internet. This places a heavy load 
on the bottleneck link of your network (probably your connection to the Internet), 
and lets you measure both the total bandwidth and the latency of the link during the transfers.

To invoke the script:

    sh netperfrunner.sh [ -4 | -6 ] [ -H netperf-server ] [ -t duration ] [ -p host-to-ping ] [-n simultaneous-streams ]

Options, if present, are:

* -H | --host: DNS or Address of a netperf server (default - netperf.bufferbloat.net)  
Alternate servers are netperf-east (east coast US), netperf-west (California), 
and netperf-eu (Denmark)
* -4 | -6: Enable ipv4 or ipv6 testing (default - ipv4)
* -t | --time: Duration for how long each direction's test should run - (default - 60 seconds)
* -p | --ping: Host to ping to measure latency (default - gstatic.com)
* -n | --number: Number of simultaneous sessions (default - 4 sessions)

The output of the script looks like this:

    root@openwrt:/usr/lib/OpenWrtScripts# sh netperfrunner.sh
    [date/time] Testing netperf.bufferbloat.net (ipv4) with 4 streams down and up 
        while pinging gstatic.com. Takes about 60 seconds.
    Download:  5.02 Mbps
      Upload:  0.41 Mbps
     Latency: (in msec, 61 pings, 15.00% packet loss)
         Min: 44.494
       10pct: 44.494
      Median: 66.438
         Avg: 68.559
       90pct: 79.049
         Max: 140.421

**Note:** The download and upload speeds reported may be considerably lower than your line's rated speed. This is not a bug, nor is it a problem with your internet connection. That's because the acknowledge messages sent back to the sender consume a significant fraction of the link's capacity (as much as 25%). 
