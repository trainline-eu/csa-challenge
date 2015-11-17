#!/usr/bin/env ruby

require 'json'
require "yaml"

MAX_STATIONS = 20
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

class Route_Step
  include Comparable
  attr_reader :trip_departure_timestamp, :arrival_timestamp,
              :connection_count, :index_in_timetable, :previous_step, :comparator_earliestarrival

  def initialize(trip_departure_timestamp, arrival_timestamp, connection_count, index_in_timetable, previous_step)
    @trip_departure_timestamp = trip_departure_timestamp
    @arrival_timestamp = arrival_timestamp
    @connection_count = connection_count
    @index_in_timetable = index_in_timetable
    @previous_step = previous_step
  end
end

comparator_earliestarrival = lambda { |a,b|

    if a.arrival_timestamp < b.arrival_timestamp
      return -1
    elsif (a.arrivalTimestamp > b.arrivalTimestamp)
      return 1
    end
    0
  }


class CSA
  attr_reader :timetable, :possible_routes, :earliest_arrival

  def initialize
    @timetable = Timetable.new
  end

  def main_loop()
    timetable.connections.each_with_index do |c, i|
      possible_routes[c.departure_station].each_with_index do |previous, j|#for each possible previous step
        if c.departure_timestamp >=  previous.arrival_timestamp
          if c.arrival_timestamp < earliest_arrival[c.arrival_station]
            earliest_arrival[c.arrival_station] = c.arrival_timestamp
          end
          possible_routes[c.arrival_station] << Route_Step.new(previous.trip_departure_timestamp ? previous.trip_departure_timestamp : c.departure_timestamp, #if not set, it is the iteration of the outter loop
                                                              c.arrival_timestamp,
                                                              previous.connection_count+1,
                                                              i,
                                                              previous
                                                            )
        end
      end
    end

  end

  def print_result(arrival_station)
    if possible_routes[arrival_station].length == 0
      puts "NO_SOLUTION"
    else
      route = []
      # We have to rebuild the route from the arrival station
      possible_routes[arrival_station].sort_by {|e| e.arrival_timestamp}
      current_route_step = possible_routes[arrival_station][0]

      while current_route_step.connection_count != -1
        route << timetable.connections[current_route_step.index_in_timetable]
        current_route_step = current_route_step.previous_step
      end


      # And now print it out in the right direction
      route.reverse.each do |c|
        STDERR.puts "#{c.departure_station} #{c.arrival_station} #{c.departure_timestamp} #{c.arrival_timestamp}"
        puts "#{c.departure_station} #{c.arrival_station} #{c.departure_timestamp} #{c.arrival_timestamp}"
      end
    end
    puts ""
    STDOUT.flush
  end

  def compute(departure_station, arrival_station, departure_time)
    @possible_routes = Array.new(MAX_STATIONS)
    @earliest_arrival = {}

    MAX_STATIONS.times do |i|
      possible_routes[i] = Array.new()
      earliest_arrival[i] = INF
    end

    earliest_arrival[departure_station] = departure_time;
    possible_routes[departure_station] << Route_Step.new(nil, #not a real departure, just a fake route_step
                                                            departure_time,
                                                            -1,
                                                            nil,
                                                            nil
                                                            )

        
    if departure_station <= MAX_STATIONS && arrival_station <= MAX_STATIONS
      main_loop()
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
