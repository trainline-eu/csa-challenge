#!/bin/bash

compute() {
    local earliest_arr in_conn route infinity
    trip_dep=$1
    trip_arr=$2
    earliest_arr[$trip_dep]=$3

    while read dep arr dep_ts arr_ts; do
        infinity=$((arr_ts + 1))
        if [ $dep_ts -ge ${earliest_arr[$dep]-$infinity} ] && \
           [ $arr_ts -lt ${earliest_arr[$arr]-$infinity} ]; then
            earliest_arr[$arr]=$arr_ts
            in_conn[$arr]="$dep $arr $dep_ts $arr_ts"
        elif [ $dep_ts -ge ${earliest_arr[$trip_arr]-$infinity} ]; then
            break
        fi
    done <<< "$timetable"

    if [ -z "${in_conn[$trip_arr]}" ]; then
        echo NO_SOLUTION
    else
        while [ $trip_arr -ne $trip_dep ]; do
            set -- ${in_conn[$trip_arr]}
            route=$@'\n'$route
            trip_arr=$1
        done
        echo -e $route
    fi
}

timetable=$(while read conn; do
    [ -z "$conn" ] && break || echo $conn
done)

while read trip; do
    [ -z "$trip" ] && break || compute $trip
done
