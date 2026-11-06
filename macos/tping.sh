#!/bin/bash

host=$1
pings_sent=0
pings_ok=0
pings_nok=0
now_ms() { python3 -c 'import time; print(int(time.time()*1000))'; }
start_time=$(now_ms)
rtt_min=
rtt_max=0
rtt_cumulative=0

if [ -z $host ]; then
    echo "Usage: `basename $0` [HOST]"
    exit 1
fi

control_c()
# run if user hits control-c
{
  packet_loss=0
  if [ $pings_sent -gt 0 ]; then
    packet_loss=$(echo "scale=1; $pings_nok * 100 / $pings_sent" | bc -l)
  fi
  ping_time=$(( $(now_ms) - start_time ))

  echo -en "\n--- $host ping statistics ---\n"
  echo -en "$pings_sent packets transmitted, $pings_ok received, $packet_loss% packet loss, time $ping_time ms\n"

  if [ $pings_ok -gt 0 ]; then
  	rtt_avg=$(echo "scale=2; $rtt_cumulative / $pings_ok" | bc)
	echo -en "rtt min/avg/max = $rtt_min/$rtt_avg/$rtt_max ms\n"
  fi

  echo -en "\n\n"

  exit $?
}
 
# trap keyboard interrupt (control-c)
trap control_c SIGINT

while :; do
    sleep 1 &  # pacer: keeps a steady 1 s interval regardless of ping duration
    pacer=$!
    result=`ping -t 1 -c 1 $host | grep -E 'bytes from .*time='`
    if [ $? -gt 0 ]; then
        echo -e "`date +'%Y/%m/%d %H:%M:%S %Z'` - host $host is \033[0;31mdown\033[0m"
        let pings_sent++
	let pings_nok++
    else
	host2=$(echo $result | sed 's/.*from \(.*\): .*/\1/')
	rtt=$(echo $result | sed 's/.*time=\(.*\) ms.*/\1/')
	rtt_cumulative=$(echo "$rtt_cumulative + $rtt" | bc)
	if [ $(echo "$rtt > $rtt_max" | bc -l) -eq 1 ]; then rtt_max=$rtt; fi
	if [ -z "$rtt_min" ] || [ $(echo "$rtt < $rtt_min" | bc -l) -eq 1 ]; then rtt_min=$rtt; fi

	echo -e "`date +'%Y/%m/%d %H:%M:%S %Z'` - host $host2 is \033[0;32mok\033[0m - time $rtt ms"
        let pings_sent++
	let pings_ok++
    fi
    wait $pacer  # avoid ping rain
done

