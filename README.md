# tping

`tping` is a timestamped ping monitor written in Bash. It pings a host once per
second and prints one line per attempt, with a date and time, whether the host
answered, and the round-trip time. It's useful for watching a connection over a
long period and seeing exactly when outages started and ended.

```
$ ./tping.sh google.com
2026/11/06 15:07:32 EET - host 108.177.14.139 is ok - time 17.452 ms
2026/11/06 15:07:33 EET - host 108.177.14.139 is ok - time 18.472 ms
2026/11/06 15:07:34 EET - host 108.177.14.139 is down
2026/11/06 15:07:35 EET - host 108.177.14.139 is ok - time 17.119 ms
^C
--- google.com ping statistics ---
4 packets transmitted, 3 received, 25.0% packet loss, time 3944 ms
rtt min/avg/max = 17.119/17.68/18.472 ms
```

Press Ctrl-C to stop. The script then prints a summary: packets sent and
received, packet loss, total run time, and minimum, average and maximum
round-trip times.

## Versions

The `ping` and `date` commands behave differently on Linux and macOS, so there
is a separate script for each:

| Script            | Platform |
|-------------------|----------|
| `linux/tping.sh`  | Linux    |
| `macos/tping.sh`  | macOS    |

The Linux version also reports duplicate replies (`DUP!`) and counts them in the
summary.

## Requirements

### Both versions

- `bash`
- `ping`
- `bc` for the round-trip and packet-loss calculations
- `grep`, `sed` and `date`

### Linux

- `ping` from **iputils**, which supports the `-W` timeout option. On
  Debian/Ubuntu this is the `iputils-ping` package.
- GNU `date` from coreutils, for the millisecond timer (`%N`). This is standard
  on most distributions.
- `bc` is missing from some minimal installs and container images. Install it
  with `sudo apt install bc` (Debian/Ubuntu) or `sudo dnf install bc`
  (Fedora/RHEL).

### macOS

- `python3`, used for the millisecond timer because macOS `date` does not
  support milliseconds. `/usr/bin/python3` comes with the Xcode Command Line
  Tools. If they aren't installed, the first call asks you to install them, or
  you can run `xcode-select --install` beforehand.
- `ping`, `bc`, `grep`, `sed` and `date` are part of macOS.

## Usage

```bash
./linux/tping.sh HOST    # on Linux
./macos/tping.sh HOST    # on macOS
```

`HOST` can be a hostname or an IP address. To run it as `tping` from anywhere,
copy the right version into a directory on your `PATH`:

```bash
cp macos/tping.sh ~/bin/tping
chmod +x ~/bin/tping
```

## How it works

- Each round sends a single ping with a 1-second timeout (`-W 1` on Linux,
  `-t 1` on macOS).
- A reply that includes a round-trip time (`time=`) counts as **ok**. Anything
  else counts as **down**: a timeout, an ICMP "Destination Host Unreachable"
  from the gateway, a DNS failure, or no route to the host.
- Each round takes 1 second, whether the ping answers immediately or waits out
  its timeout.
