#!/bin/bash

url=$1
curls_sent=0
curls_ok=0
curls_nok=0
start_time=`date +%s%3N`
time_cumulative=0

if [ -z $url ]; then
    echo "Usage: `basename $0` [URL]"
    exit 1
fi

control_c()
# run if user hits control-c
{
  curls_failed_percent=$(echo "scale=1; $curls_nok / $curls_sent * 100" | bc -l)
  test_time=$(echo "`date +%s%3N` - $start_time" | bc)

  echo -en "\n--- $url curl statistics ---\n"
  echo -en "$curls_sent culr requests transmitted, $curls_ok ok, $curls_nok not ok, failed $curls_failed_percent%, time $test_time ms\n"

  if [ $curls_ok -gt 0 ]; then
        time_avg=$(echo "scale=2; $time_cumulative / $curls_ok" | bc)
        echo -en "Time average for code 200 gets $time_avg s\n"
  fi

  echo -en "\n\n"

  exit $?
}

# trap keyboard interrupt (control-c)
trap control_c SIGINT

while :; do
    response=$(curl -L --write-out "%{url_effective};%{http_code};%{time_total}\n" --silent --max-time 1 --output /dev/null "$url")
	url_effective="$( cut -d ';' -f 1 <<< "$response" )"
	http_code="$( cut -d ';' -f 2 <<< "$response" )"
	time_total="$( cut -d ';' -f 3 <<< "$response" )"

    if [ $http_code -ne 200 ]; then
        echo -e "`date +'%Y/%m/%d %H:%M:%S %Z'` - $url_effective - $http_code - $time_total - \033[0;31mNOT OK\033[0m"
        let curls_sent++
        let curls_nok++
    else
        echo -e "`date +'%Y/%m/%d %H:%M:%S %Z'` - $url_effective - $http_code - $time_total - \033[0;32mok\033[0m"
		time_cumulative=$(echo "$time_cumulative + $time_total" | bc)
		let curls_sent++
        let curls_ok++
    fi

    sleep 1
done
