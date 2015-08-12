import java.io.*;
import java.util.*;

class Connection {
    int departure_station, arrival_station;
    int departure_timestamp, arrival_timestamp;

    // Connection constructor
    Connection(String line) {
        line.trim();
        String[] tokens = line.split(" ");

        departure_station = Integer.parseInt(tokens[0]);
        arrival_station = Integer.parseInt(tokens[1]);
        departure_timestamp = Integer.parseInt(tokens[2]);
        arrival_timestamp = Integer.parseInt(tokens[3]);
    }
};

class Timetable {
    List<Connection> connections;

    // Timetable constructor: reads all the connections from stdin
    Timetable(BufferedReader in) {
        connections = new ArrayList<Connection>();
        String line;
        try {
            line = in.readLine();

            while (!line.isEmpty()) {
                connections.add( new Connection(line) );
                line = in.readLine();
            }
        } catch( Exception e) {
            System.out.println("Something went wrong while reading the data: " + e.getMessage());
        }
    }
};

public class CSA {
    public static final int MAX_STATIONS  = 100000;

    Timetable timetable;
    Connection in_connection[];
    int earliest_arrival[];

    CSA(BufferedReader in) {
        timetable = new Timetable(in);
    }

    void main_loop(int arrival_station) {
        int earliest = Integer.MAX_VALUE;
        for (Connection connection: timetable.connections) {
            if (connection.departure_timestamp >= earliest_arrival[connection.departure_station] &&
                    connection.arrival_timestamp < earliest_arrival[connection.arrival_station]) {
                earliest_arrival[connection.arrival_station] = connection.arrival_timestamp;
                in_connection[connection.arrival_station] = connection;

                if(connection.arrival_station == arrival_station) {
                    earliest = Math.min(earliest, connection.arrival_timestamp);
                }
            } else if(connection.arrival_timestamp > earliest) {
                return;
            }
        }
    }

    void print_result(int arrival_station) {
        if(in_connection[arrival_station] == null) {
            System.out.println("NO_SOLUTION");
        } else {
            List<Connection> route = new ArrayList<Connection>();
            // We have to rebuild the route from the arrival station 
            Connection last_connection = in_connection[arrival_station];
            while (last_connection != null) {
                route.add(last_connection);
                last_connection = in_connection[last_connection.departure_station];
            }

            // And now print it out in the right direction
            Collections.reverse(route);
            for (Connection connection : route) {
                System.out.println(connection.departure_station + " " + connection.arrival_station + " " +
                        connection.departure_timestamp + " " + connection.arrival_timestamp);
            }
        }
        System.out.println("");
        System.out.flush();
    }

    void compute(int departure_station, int arrival_station, int departure_time) {
        in_connection = new Connection[MAX_STATIONS];
        earliest_arrival = new int[MAX_STATIONS];
        for(int i = 0; i < MAX_STATIONS; ++i) {
            in_connection[i] = null;
            earliest_arrival[i] = Integer.MAX_VALUE;
        }
        earliest_arrival[departure_station] = departure_time;

        if (departure_station <= MAX_STATIONS && arrival_station <= MAX_STATIONS) {
            main_loop(arrival_station);
        }
        print_result(arrival_station);
    }

    public static void main(String[] args) {
        BufferedReader in = new BufferedReader(new InputStreamReader(System.in));
        CSA csa = new CSA(in);

        String line;
        try {
            line = in.readLine();

            while (!line.isEmpty()) {
                String[] tokens = line.split(" ");
                csa.compute(Integer.parseInt(tokens[0]), Integer.parseInt(tokens[1]), Integer.parseInt(tokens[2]));
                line = in.readLine();
            }
        } catch( Exception e) {
            System.out.println("Something went wrong while reading the parameters: " + e.getMessage());
        }
    }
}
