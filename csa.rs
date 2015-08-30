use std::io;
use std::iter::repeat;

const MAX_STATIONS: usize = 100000;

#[derive(Debug)]
struct Connection {
    departure_station: usize,
    arrival_station: usize,
    departure_timestamp: u32,
    arrival_timestamp: u32
}

impl Connection {
    fn parse(line: &str) -> Connection {
        let mut splitted = line.split(" ").map(|bite| { bite.parse::<u32>().unwrap() });

        Connection {
            departure_station: splitted.next().unwrap() as usize,
            arrival_station: splitted.next().unwrap() as usize,
            departure_timestamp: splitted.next().unwrap(),
            arrival_timestamp: splitted.next().unwrap(),
        }
    }
}

fn csa_main_loop(timetable: &[Connection], arrival_station: usize, earliest_arrival: &mut [u32], in_connection: &mut [usize]) {
    let mut earliest = std::u32::MAX;

    for (i, connection) in timetable.iter().enumerate() {
        if connection.departure_timestamp >= earliest_arrival[connection.departure_station] &&
                connection.arrival_timestamp < earliest_arrival[connection.arrival_station] {
            earliest_arrival[connection.arrival_station] = connection.arrival_timestamp;
            in_connection[connection.arrival_station] = i;

            if connection.arrival_station == arrival_station && connection.arrival_timestamp < earliest {
                earliest = connection.arrival_timestamp;
            }
        } else if connection.arrival_timestamp > earliest {
            break;
        }
    }
}

fn csa_print_result(timetable: &Vec<Connection>, in_connection: &[usize], arrival_station: usize) {
    if in_connection[arrival_station] == std::u32::MAX as usize {
        println!("NO_SOLUTION");
    } else {
        let mut route = Vec::new();
        let mut last_connection_index = in_connection[arrival_station];

        while last_connection_index != std::u32::MAX as usize {
            let ref connection = timetable[last_connection_index];
            route.push(connection);
            last_connection_index = in_connection[connection.departure_station];
        }

        for connection in route.iter().rev() {
            println!("{} {} {} {}", connection.departure_station, connection.arrival_station, connection.departure_timestamp, connection.arrival_timestamp);
        }
    }
    println!("");
}

fn csa_compute(timetable: &Vec<Connection>, departure_station: usize, arrival_station: usize, departure_time: u32)
{
    let mut in_connection = Vec::new();
    in_connection.extend(repeat(std::u32::MAX as usize).take(MAX_STATIONS));
    let mut earliest_arrival = Vec::new();
    earliest_arrival.extend(repeat(std::u32::MAX).take(MAX_STATIONS));

    earliest_arrival[departure_station as usize] = departure_time;

    if departure_station < MAX_STATIONS && arrival_station < MAX_STATIONS {
        csa_main_loop(&timetable, arrival_station, &mut earliest_arrival, &mut in_connection);
    }

    csa_print_result(&timetable, &in_connection, arrival_station);
}

fn main() {
    let mut timetable = Vec::<Connection>::new();

    // Importing connections

    loop {
        let raw_line = {
            let mut line = String::new();
            io::stdin().read_line(&mut line).ok().expect("failed to read connection line");
            line
        };
        let input_line = raw_line.trim_right();

        if input_line.is_empty() {
            break;
        } else {
            timetable.push(Connection::parse(input_line));
        };
    }

    // Responding to requests from stdin

    loop {
        let raw_line = {
            let mut line = String::new();
            io::stdin().read_line(&mut line).ok().expect("failed to read connection line");
            line
        };
        let input_line = raw_line.trim_right();

        if input_line.is_empty() {
            break;
        } else {
            let params = input_line.split(" ")
                .map(|bite| { bite.parse().ok().expect(&format!("failed to read {} as integer", bite)) })
                .collect::<Vec<u32>>();

            let departure_station = params[0] as usize;
            let arrival_station = params[1] as usize;
            let departure_time = params[2];

            csa_compute(&timetable, departure_station, arrival_station, departure_time);
        }
    }
}
