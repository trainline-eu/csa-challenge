#!/usr/bin/env ruby

MAX_STATIONS = 100000
INF = 1.0/0

class Connection
  attr_reader :departure_station, :arrival_station,
              :departure_timestamp, :arrival_timestamp

  def initialize(line)
    tokens = line.split(" ")

    @departure_station    = tokens[0].to_i
    @arrival_station      = tokens[1].to_i
    @departure_timestamp  = tokens[2].to_i
    @arrival_timestamp    = tokens[3].to_i
  end
end

class Timetable
  attr_reader :connections

  # reads all the connections from stdin
  def initialize
    @connections = []
    line = STDIN.gets.strip

    while !line.empty?
      @connections << Connection.new(line)
      line = STDIN.gets.strip
    end
  end
end

class CSA
  attr_reader :timetable, :in_connection, :earliest_arrival

  def initialize
    @timetable = Timetable.new
  end

  def main_loop(arrival_station)
    earliest = INF
    timetable.connections.each_with_index do |c, i|
      if c.departure_timestamp >= earliest_arrival[c.departure_station] && c.arrival_timestamp < earliest_arrival[c.arrival_station]
        earliest_arrival[c.arrival_station] = c.arrival_timestamp
        in_connection[c.arrival_station] = i
        if c.arrival_station == arrival_station
          earliest = [earliest, c.arrival_timestamp].min
        end
      elsif c.arrival_timestamp > earliest
        return
      end
    end
  end

  def print_result(arrival_station)
    if in_connection[arrival_station] == INF
      puts "NO_SOLUTION"
    else
      route = []
      # We have to rebuild the route from the arrival station
      last_connection_index = in_connection[arrival_station]
      while last_connection_index != INF
        connection = timetable.connections[last_connection_index]
        route << connection
        last_connection_index = in_connection[connection.departure_station]
      end

      # And now print it out in the right direction
      route.reverse.each do |c|
        puts "#{c.departure_station} #{c.arrival_station} #{c.departure_timestamp} #{c.arrival_timestamp}"
      end
    end
    puts ""
    STDOUT.flush
  end

  def compute(departure_station, arrival_station, departure_time)
    @in_connection = {}
    @earliest_arrival = {}

    MAX_STATIONS.times do |i|
      in_connection[i] = INF
      earliest_arrival[i] = INF
    end

    earliest_arrival[departure_station] = departure_time;

    if departure_station <= MAX_STATIONS && arrival_station <= MAX_STATIONS
      main_loop(arrival_station)
    end

    print_result(arrival_station)
  end
end

def main
  csa = CSA.new

  line = STDIN.gets.strip

  while !line.empty?
    tokens = line.split(" ")
    csa.compute(tokens[0].to_i, tokens[1].to_i, tokens[2].to_i)
    line = STDIN.gets.strip
  end
end

main
