#include <boost/algorithm/string.hpp>
#include <iostream>
#include <limits>
#include <stdint.h>
#include <vector>

const int MAX_STATIONS  = 100000;
const uint32_t INF = std::numeric_limits<uint32_t>::max();

struct Connection {
    uint32_t departure_station, arrival_station;
    uint32_t departure_timestamp, arrival_timestamp;

    // Connection constructor
    Connection(std::string line) {
        boost::trim(line);
        std::vector<std::string> tokens;
        boost::split(tokens, line, boost::is_any_of(" "));

        departure_station = std::stoi(tokens[0]);
        arrival_station = std::stoi(tokens[1]);
        departure_timestamp = std::stoi(tokens[2]);
        arrival_timestamp = std::stoi(tokens[3]);
    }
};

struct Timetable {
    std::vector<Connection> connections;

    // Timetable constructor: reads all the connections from stdin
    Timetable() {
        std::string line;
        getline(std::cin, line);

        while (!line.empty()) {
            connections.push_back( Connection(line) );
            getline(std::cin, line);
        }
    }
};

struct CSA {
    Timetable timetable;
    std::vector<uint32_t> in_connection;
    std::vector<uint32_t> earliest_arrival;

    void main_loop(uint32_t arrival_station) {
        uint32_t earliest = INF;
        for (size_t i = 0; i < timetable.connections.size(); ++i) {
            Connection connection = timetable.connections[i];

            if (connection.departure_timestamp >= earliest_arrival[connection.departure_station] &&
                    connection.arrival_timestamp < earliest_arrival[connection.arrival_station]) {
                earliest_arrival[connection.arrival_station] = connection.arrival_timestamp;
                in_connection[connection.arrival_station] = i;

                if(connection.arrival_station == arrival_station) {
                    earliest = std::min(earliest, connection.arrival_timestamp);
                }
            } else if(connection.arrival_timestamp > earliest) {
              return;
            }
        }
    }

    void print_result(uint32_t arrival_station) {
        if(in_connection[arrival_station] == INF) {
            std::cout << "NO_SOLUTION" << std::endl;
        } else {
            std::vector<Connection> route;
            // We have to rebuild the route from the arrival station
            uint32_t last_connection_index = in_connection[arrival_station];
            while (last_connection_index != INF) {
                Connection connection = timetable.connections[last_connection_index];
                route.push_back(connection);
                last_connection_index = in_connection[connection.departure_station];
            }

            // And now print it out in the right direction
            std::reverse(route.begin(), route.end());
            for (auto connection : route) {
                std::cout << connection.departure_station << " " << connection.arrival_station << " " <<
                    connection.departure_timestamp << " " << connection.arrival_timestamp << std::endl;
            }
        }
        std::cout << std::endl;
    }

    void compute(uint32_t departure_station, uint32_t arrival_station, uint32_t departure_time) {
        in_connection.assign(MAX_STATIONS, INF);
        earliest_arrival.assign(MAX_STATIONS, INF);
        earliest_arrival[departure_station] = departure_time;

        if (departure_station <= MAX_STATIONS && arrival_station <= MAX_STATIONS) {
            main_loop(arrival_station);
        }
        print_result(arrival_station);
    }
};

int main(int, char**) {
    CSA csa;

    std::string line;
    std::vector<std::string> tokens;
    getline(std::cin, line);

    while (!line.empty()) {
        boost::split(tokens, line, boost::is_any_of(" "));
        csa.compute(std::stoi(tokens[0]), std::stoi(tokens[1]), std::stoi(tokens[2]));
        getline(std::cin, line);
    }
}
