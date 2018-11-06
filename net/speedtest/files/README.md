Network Performance Testing
===========================

## Introduction

The `speedtest` package provides a convenient means of performance testing from an OpenWrt router. `speedtest` is an easy install using the `opkg` utility. The script characterizes the network throughput and latency, as well as CPU usage. 

1. **Throughput:** Network speed measurements can help troubleshoot transfer problems, and be used to determine whether an ISP is delivering their promised speeds. This test provices accurate throughput numbers to guide settings for other software, such as [setting SQM ingress/egress rates](https://openwrt.org/docs/guide-user/network/traffic-shaping/sqm) or bandwidth limits for Bittorrent.

2. **Latency:** Low network latency is a key factor when using real-time or interactive applications such as VOIP, gaming, or video conferencing. Excessive latency can lead to undesirable dropouts, freezes and lag. Such latency problems are endemic on the Internet and are often the result of [bufferbloat](https://www.bufferbloat.net/projects/). This test provides consistent latency measurements to identify and mitigate bufferbloat.

3. **CPU Usage:**  Observing CPU usage under network load gives insight into whether the router is CPU-bound, or if there is CPU "headroom" to support even higher network throughput. In addition to managing network traffic, a router actively running a `speedtest` will also use CPU cycles to generate network load. This test measures both the overall CPU usage, as well as the impact of the `speedtest` script itself.

**Note:** _The `speedtest.sh` script uses servers and network bandwidth that are provided by generous volunteers (not some wealthy "big company"). Feel free to use the script to test your SQM configuration or troubleshoot network and latency problems. Continuous or high rate use of this script may result in denied access. Happy testing!_


## Theory of Operation

When launched, `speedtest.sh` runs the (local) `netperf` application to upload and download streams (files) with a server on the Internet. This places a heavy traffic load on the bottleneck link of your network (probably your connection to the Internet) while simultaneously measuring: 
* the total bandwidth of the link during the transfers,
* the latency of pings to see whether the file transfers affect the responsiveness of your network, and
* the per-CPU processor usage, as well as the CPU usage of the `netperf` instances used for the test.

The script operates in two distict modes for network loading: *sequential* and *concurrent*. In the default sequential mode, the script emulates other web-based speed tests by first downloading and then uploading network streams. In concurrent mode, the script mimics the stress test of the [FLENT](https://github.com/tohojo/flent) program by dowloading and uploading streams simultaneously.

*Sequential mode* is best to measure peak upload and download speeds for SQM configuration or testing ISP speed claims, because the measurements are (minimally) impacted by traffic in the opposite direction.

*Concurrent mode* places greater stress on the network, and can expose additional latency problems. It provides a more realistic estimate of expected bidirectional throughput. However, the download and upload speeds reported may be considerably lower than your line's rated speed. This is not a bug, nor is it a problem with your internet connection. It's because the ACK (acknowledge) messages sent back to the sender may consume a significant fraction of a link's capacity (as much as 50% with highly asymmetric links, e.g 15:1 or 20:1).

If `speedtest.sh` shows latency increasing much during the data transfers, then other network activity, such as voice or video chat, gaming, and general interactive usage will likely suffer. Gamers will see this as frustrating lag when someone else uses the network, Skype and FaceTime users will see dropouts or freezes, and VOIP service may be unusable.

## Installation

The `speedtest` package and its dependencies can be installed directly from the official OpenWrt software repository with the command:
`# opkg install speedtest`

If the package is not yet available, or to install the very latest version of the package, download it directly from the author's repo:
```
# cd /tmp
# uclient-fetch https://github.com/guidosarducci/papal-repo/raw/master/speedtest_0.9-4_all.ipk
# opkg install speedtest_0.9-4_all.ipk
```

## Usage

The speedtest.sh script measures throughput, latency and CPU usage during file transfers. To invoke it:

    speedtest.sh [-4 | -6] [-H netperf-server] [-t duration] [-p host-to-ping] [-n simultaneous-streams ] [-s | -c]

Options, if present, are:

    -4 | -6:           Enable ipv4 or ipv6 testing (default - ipv4)
    -H | --host:       DNS or Address of a netperf server (default - netperf.bufferbloat.net)  
                       Alternate servers are netperf-east (US, east coast),
                       netperf-west (US, California), and netperf-eu (Denmark).
    -t | --time:       Duration for how long each direction's test should run - (default - 60 seconds)
    -p | --ping:       Host to ping to measure latency (default - gstatic.com)
    -n | --number:     Number of simultaneous sessions (default - 5 sessions)
    -s | --sequential: Sequential download/upload (default - sequential)
    -c | --concurrent: Concurrent download/upload

The output shows download and upload speeds, percent packet loss, a summary of latencies, including min, max, average, median, and 10th and 90th percentiles so you can get a sense of the distribution, and a summary of CPU usage during the test, both per-CPU and for the `netperf` programs.

### Examples
The sequential speedtest runs below show the benefits of SQM. On the left is a test without SQM. Note that the latency gets large (greater than half a second), meaning that network performance would be poor for anyone else using the network. On the right is a test with SQM enabled: the latency goes up a little (less than 21 msec under load), and network performance remains good.

Notice also that the activation of SQM requires greater CPU, but that in both cases the router is not CPU-bound and likely capable of supporting higher throughputs.

```
[Sequential Test: NO SQM, POOR LATENCY]                       [Sequential Test: WITH SQM, GOOD LATENCY]
# speedtest.sh                                                # speedtest.sh
[date/time] Starting speedtest for 60 seconds per transfer    [date/time] Starting speedtest for 60 seconds per transfer
session. Measure speed to netperf.bufferbloat.net (IPv4)      session. Measure speed to netperf.bufferbloat.net (IPv4)
while pinging gstatic.com. Download and upload sessions are   while pinging gstatic.com. Download and upload sessions are
sequential, each with 5 simultaneous streams.                 sequential, each with 5 simultaneous streams.

 Download:  35.40 Mbps                                         Download:  32.69 Mbps
  Latency: (in msec, 61 pings, 0.00% packet loss)               Latency: (in msec, 61 pings, 0.00% packet loss)
      Min: 10.228                                                   Min: 9.388
    10pct: 38.864                                                 10pct: 12.038
   Median: 47.027                                                Median: 14.550
      Avg: 45.953                                                   Avg: 14.827
    90pct: 51.867                                                 90pct: 17.122
      Max: 56.758                                                   Max: 20.558
Processor: (in % busy, avg +/- stddev, 57 samples)            Processor: (in % busy, avg +/- stddev, 55 samples)
     cpu0: 56 +/-  6                                               cpu0: 82 +/-  5
 Overhead: (in % total CPU used)                               Overhead: (in % total CPU used)
  netperf: 34                                                   netperf: 51

   Upload:   5.38 Mbps                                           Upload:   5.16 Mbps
  Latency: (in msec, 62 pings, 0.00% packet loss)               Latency: (in msec, 62 pings, 0.00% packet loss)
      Min: 11.581                                                   Min: 9.153
    10pct: 424.616                                                10pct: 10.401
   Median: 504.339                                               Median: 14.151
      Avg: 491.511                                                  Avg: 14.056
    90pct: 561.466                                                90pct: 17.241
      Max: 580.896                                                  Max: 20.733
Processor: (in % busy, avg +/- stddev, 60 samples)            Processor: (in % busy, avg +/- stddev, 59 samples)
     cpu0: 11 +/-  5                                               cpu0: 16 +/-  5
 Overhead: (in % total CPU used)                               Overhead: (in % total CPU used)
  netperf:  1                                                   netperf:  1
```

The concurrent runs below show another comparison without and with SQM. Notice that without SQM, the total throughput drops nearly 11 Mbps compared to the above sequential test without SQM. This is due to both poorer latencies and the consumption of bandwidth by ACK messages. As before, the use of SQM on the right not only yields a marked improvement in latencies, but also recovers almost 6 Mbps in throughput (with SQM using CAKE's ACK filtering).
```
[Concurrent Test: NO SQM, POOR LATENCY]                       [Concurrent Test: WITH SQM, GOOD LATENCY]
# speedtest.sh --concurrent                                   # speedtest.sh --concurrent
[date/time] Starting speedtest for 60 seconds per transfer    [date/time] Starting speedtest for 60 seconds per transfer
session. Measure speed to netperf.bufferbloat.net (IPv4)      session. Measure speed to netperf.bufferbloat.net (IPv4)
while pinging gstatic.com. Download and upload sessions are   while pinging gstatic.com. Download and upload sessions are
concurrent, each with 5 simultaneous streams.                 concurrent, each with 5 simultaneous streams.

 Download:  25.24 Mbps                                         Download:  31.92 Mbps
   Upload:   4.75 Mbps                                           Upload:   4.41 Mbps
  Latency: (in msec, 59 pings, 0.00% packet loss)               Latency: (in msec, 61 pings, 0.00% packet loss)
      Min: 9.401                                                    Min: 10.244
    10pct: 129.593                                                10pct: 13.161
   Median: 189.312                                               Median: 16.885
      Avg: 195.418                                                  Avg: 17.219
    90pct: 226.628                                                90pct: 21.166
      Max: 416.665                                                  Max: 28.224
Processor: (in % busy, avg +/- stddev, 59 samples)            Processor: (in % busy, avg +/- stddev, 56 samples)
     cpu0: 45 +/- 12                                               cpu0: 86 +/-  4
 Overhead: (in % total CPU used)                               Overhead: (in % total CPU used)
  netperf: 25                                                   netperf: 42
```

## Provenance

The `speedtest.sh` script combines earlier scripts from the CeroWrt project used to measure network throughput and latency, as part of overall bufferbloat mitigation. The original scripts [betterspeedtest.sh](https://github.com/richb-hanover/OpenWrtScripts#betterspeedtestsh) (emulates a web-based speed test by downloading from and then uploading to an internet server) and [netperfrunner.sh](https://github.com/richb-hanover/OpenWrtScripts#netperfrunnersh) (performs a simultaneous download and upload from an internet server, simulating the FLENT test program) are used with the permission of their author, [Rich Brown](https://github.com/richb-hanover/OpenWrtScripts). Many thanks, Rich!
