# CSA Challenge

At Capitaine Train, we need to compute train routes to find the best combination
with different train operators.

Our core routing engine is written in C++ and is based on the
Connection Scan Algorithm.

We had many conversations, both trolls and genuine curiosity how the routing works.

So we decided a very simple challenge: implement your own routing engine. It is the best
way to learn how the algorithm works and prove that your language is the most expressive,
the most to fun to write code with, the fastest, the safest…

## The data

The timetable is expressed by a collection of tuples (departure station, arrival station, departure timestamp, arrival timestamp).

The stations are identified by an index. Timestamps are unix timestamp. Do not worry about timezones, validity days etc. We crunched the data before. It is not the most
memory efficient implementation, but it is the easiest (and some argue with the best performance).

Every tuple is called a *connection*. So the connection (1, 2, 3600, 7200) means that you can take a train from station 1 the
1st of January 1970 at 1:00 and the following stop of the train will be at 2:00 at the station 2.

The data will be provided as a space separated values.

The tuple are ordered by departure timestamp stored in an indexed array.

## The algorithm

The CSA is very simple. For every station `s` we keep the best arrival time and arrival connection. We call those two connections
`arrival_timestamp[s]` and `in_connection[s]`.

We want to go from `o` to `d` leaving at the timestamp `t0`

### Initialisation

```
For each station s
    arrival_timestamp[s] = infinite
    in_connection[s] = invalid_value

arrival_timestamp[o] = t0
```

### Main loop

We iterate over all the connections to see if we can improve any connection.

Once we have explored all connections, we have computed all the earliest arrival routes from `o` to any other station.

```
For each connection c
    if arrival_timestamp[c.departure_station] < c.departure_timestamp and arrival_timestamp[c.arrival_station] > c.arrival_timestamp
        arrival_timestamp[c.arrival_station] ← c.arrival_timestamp
        in_connection[c.arrival_station] = c
```

### Getting the actual path back

We just need to go from `d` and look up all the in_connections until we reach `o` and we have the path and the timetable.

### Immediate optimizations

There is no need to look all the connections. We start with the first having `departure_timestamp > t0` and we stop
as soon as `c.departure_timestamp > arrival_timestamp`.

## Limitations

While this algorithm find routes, there are the following limitations to be aware of:

* it computes the earliest arrival. However, a better solution might leaver later an arrive at the same time
* the route with the least connections will not be computed
* no connection time is considered: you might have to run to get the next train
* multiple stations in a City like Paris are not considered

## Input/output

Your program should read from the standard input.

The timetable is given one connection per line, each value of the tuple is space separated.

An empty line indicates that the input is done. The following lines are a route request with three values separated by spaces:
`departure_station arrival_station departure_timestamp`. A new line indicates that the program should stop.

Here is a example of input

```
1 2 3600 7200
2 3 7800 9000

1 3 3000

```

The output should be a line for each connection on the standart output. An empty line indicates the end of the output. Hence the answer shall be

```
1 2 3600 7200
2 3 7800 9000

```

## Reference implementation

An implementation in C++11 is available.

It can be compiled with ```g++ $CPPFLAGS --std=c++11 -O3 -o csa_cpp csa.cc```

Run the test with ```ruby test.rb ./csa_cpp```


## Challenge

Try to write:

* The first implementation passing the tests
* Smallest source code (measured in bytes). Any library installable without an external repository on Debian, Ubuntu, Archlinux is accepted
* Smallest executable (same rule considering dependencies)
* The most unreable
* The least alphanumerical characters
* The most creative implementation of the algorithm
