#!/usr/bin/env python3

import sys

MAX_STATIONS = 100000


class Connection:
    def __init__(self, line):
        tokens = line.split(" ")

        self.departure_station = int(tokens[0])
        self.arrival_station = int(tokens[1])
        self.departure_timestamp = int(tokens[2])
        self.arrival_timestamp = int(tokens[3])


class Timetable:
    # reads all the connections from stdin
    def __init__(self):
        self.connections = []

        for line in sys.stdin:
            if line.rstrip() == "":
                break

            self.connections.append(Connection(line.rstrip()))


class CSA:
    def __init__(self):
        self.timetable = Timetable()
        self.in_connection = []
        self.earliest_arrival = []

    def main_loop(self, arrival_station):
        earliest = float("inf")

        for i, c in enumerate(self.timetable.connections):
            if c.departure_timestamp >= self.earliest_arrival[c.departure_station] \
                    and c.arrival_timestamp < self.earliest_arrival[c.arrival_station]:
                self.earliest_arrival[c.arrival_station] = c.arrival_timestamp
                self.in_connection[c.arrival_station] = i

                if c.arrival_station == arrival_station:
                    earliest = min(earliest, c.arrival_timestamp)
            elif c.arrival_timestamp > earliest:
                return

    def print_result(self, arrival_station):
        if self.in_connection[arrival_station] == float("inf"):
            print("NO_SOLUTION")
        else:
            route = []

            # We have to rebuild the route from the arrival station
            last_connection_index = self.in_connection[arrival_station]

            while last_connection_index != float("inf"):
                connection = self.timetable.connections[last_connection_index]
                route.append(connection)
                last_connection_index = self.in_connection[connection.departure_station]

            # And now print it out in the right direction
            for c in reversed(route):
                print("{} {} {} {}".format(
                    c.departure_station,
                    c.arrival_station,
                    c.departure_timestamp,
                    c.arrival_timestamp
                ))

        print("")
        try:
            sys.stdout.flush()
        except BrokenPipeError:
            pass

    def compute(self, departure_station, arrival_station, departure_time):
        self.in_connection = {}
        self.earliest_arrival = {}

        for i in range(MAX_STATIONS):
            self.in_connection[i] = float("inf")
            self.earliest_arrival[i] = float("inf")

        self.earliest_arrival[departure_station] = departure_time

        if departure_station <= MAX_STATIONS and arrival_station <= MAX_STATIONS:
            self.main_loop(arrival_station)

        self.print_result(arrival_station)


def main():
    csa = CSA()

    for line in sys.stdin:
        if line.rstrip() == "":
            break

        tokens = line.rstrip().split(" ")
        csa.compute(int(tokens[0]), int(tokens[1]), int(tokens[2]))

    sys.stdin.close()

if __name__ == '__main__':
    main()
