#!/usr/bin/env ruby

require 'json'
require "yaml"

MAX_STATIONS = 20
INF = 1.0/0
TRANSFER_TIME_THRESHOLD = 900

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

class SameCityConnection
  attr_reader :departure_station, :arrival_station,
              :transfer_time

  def initialize(line)
    tokens = line.split(" ")

    @departure_station    = tokens[0].to_i
    @arrival_station      = tokens[1].to_i
    @transfer_time        = tokens[2].to_i
  end
end



class Timetable
  attr_reader :connections
  attr_reader :same_city_connections

  # reads all the connections from stdin
  def initialize
    @connections = []
    @same_city_connections = []
    line = STDIN.gets.strip

    while !line.empty?
      @connections << Connection.new(line)
      line = STDIN.gets.strip
    end

    line = STDIN.gets.strip

    while !line.empty?
      @same_city_connections << SameCityConnection.new(line)
      tokens = line.split(" ")
      tokens = [tokens[1], tokens[0], tokens[2]]
      @same_city_connections << SameCityConnection.new(tokens.join(" "))
      line = STDIN.gets.strip
    end


  end
end

class Route_Step
  include Comparable
  attr_reader :trip_departure_timestamp, :arrival_timestamp,
              :connection_count, :index_in_timetable, :previous_step, :min_transfer_time, :city_connection

  def initialize(trip_departure_timestamp, arrival_timestamp, connection_count, index_in_timetable, previous_step, min_transfer_time, city_connection)
    @trip_departure_timestamp = trip_departure_timestamp
    @arrival_timestamp = arrival_timestamp
    @connection_count = connection_count
    @index_in_timetable = index_in_timetable
    @min_transfer_time = min_transfer_time
    @previous_step = previous_step
    @city_connection = city_connection
  end
end


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
          added_step = Route_Step.new(previous.trip_departure_timestamp ? previous.trip_departure_timestamp : c.departure_timestamp, #if not set, it is the iteration of the outter loop
                                                              c.arrival_timestamp,
                                                              previous.connection_count+1,
                                                              i,
                                                              previous,
                                                              previous.connection_count >= 0  ? [previous.min_transfer_time, c.departure_timestamp - previous.arrival_timestamp].min : previous.min_transfer_time,
                                                              nil
                                                            )
          possible_routes[c.arrival_station] << added_step
          # try to add possibile same city connection
          timetable.same_city_connections.select{|con| con.departure_station == c.arrival_station} #trip_departure_timestamp, arrival_timestamp, connection_count, index_in_timetable, previous_step, min_transfer_time, city_connection
                                          .each{|c|  possible_routes[c.arrival_station] << Route_Step.new(added_step.trip_departure_timestamp, 
                                                                                                          added_step.arrival_timestamp + c.transfer_time,
                                                                                                          added_step.connection_count+1,
                                                                                                          nil,
                                                                                                          added_step,
                                                                                                          added_step.min_transfer_time,
                                                                                                          Connection.new([ c.departure_station, c.arrival_station, added_step.arrival_timestamp, added_step.arrival_timestamp + c.transfer_time].join(" "))
                                                                                                          )
                                                    earliest_arrival[c.arrival_station] = added_step.arrival_timestamp + c.transfer_time
                                        }

        end
      end
    end

  end

  def has_result_or_report(arrival_station)
    if possible_routes[arrival_station].length == 0
      STDERR.puts "NO_SOLUTION"
      puts "NO_SOLUTION"
      return false
    else
      return true
    end
  end

  def compute_route(arrival_station, order_criteria, filter_criteria)
    route = []
    # We have to rebuild the route from the arrival station
    possibilities = possible_routes[arrival_station].select &filter_criteria
    possibilities = possibilities.sort_by &order_criteria
    current_route_step = possibilities[0]

    has_short_transfers = current_route_step.min_transfer_time < TRANSFER_TIME_THRESHOLD

    while current_route_step.connection_count != -1
      if(current_route_step.index_in_timetable)
        route << timetable.connections[current_route_step.index_in_timetable]
      else
        route << current_route_step.city_connection
      end
      current_route_step = current_route_step.previous_step
    end

    return route.reverse, has_short_transfers  #return two values using destructuration 
  end

  def print_result(route, solution_type_prefix)   
    
    route.each do |c|
      STDERR.puts "#{solution_type_prefix} #{c.departure_station} #{c.arrival_station} #{c.departure_timestamp} #{c.arrival_timestamp}"
      puts "#{solution_type_prefix} #{c.departure_station} #{c.arrival_station} #{c.departure_timestamp} #{c.arrival_timestamp}"
    end
    
  end

  def compute(departure_station, arrival_station, departure_time)
    @possible_routes = Array.new(MAX_STATIONS)
    @earliest_arrival = {}

    MAX_STATIONS.times do |i|
      possible_routes[i] = Array.new()
      earliest_arrival[i] = INF
    end

    earliest_arrival[departure_station] = departure_time;
    first_step = Route_Step.new(nil, #not a real departure, just a fake route_step
                                departure_time,
                                -1,
                                nil,
                                nil,
                                INF,
                                nil
                                )
    possible_routes[departure_station] << first_step

    # try to add possibile same city connection
    timetable.same_city_connections.select{|c| 
                                             c.departure_station == departure_station} #trip_departure_timestamp, arrival_timestamp, connection_count, index_in_timetable, previous_step, min_transfer_time, city_connection
                                   .each{|c|  possible_routes[c.arrival_station] << Route_Step.new(departure_time, 
                                                                                                    departure_time + c.transfer_time,
                                                                                                    first_step.connection_count+1,
                                                                                                    nil,
                                                                                                    first_step,
                                                                                                    INF,
                                                                                                    Connection.new([departure_station, c.arrival_station, departure_time, departure_time + c.transfer_time].join(" "))
                                                                                                )
                                              earliest_arrival[c.arrival_station] = departure_time + c.transfer_time
                                        }



        
    if departure_station <= MAX_STATIONS && arrival_station <= MAX_STATIONS
      main_loop()
    end

    if(has_result_or_report(arrival_station))
      route, has_short_transfers = compute_route(arrival_station, lambda  {|e| [e.arrival_timestamp, -e.trip_departure_timestamp]}, lambda {|e| true})
      print_result(route, "EARLIEST_ARRIVAL") 
      if(has_short_transfers)
        route, has_short_transfers = compute_route(arrival_station, lambda  {|e| [e.arrival_timestamp, -e.trip_departure_timestamp]}, lambda {|e| e.min_transfer_time > TRANSFER_TIME_THRESHOLD})
        print_result(route, "EARLIEST_ARRIVAL_WITH_EASY_TRANSFERS")  
      end 
      route, has_short_transfers = compute_route(arrival_station, lambda  {|e| [e.connection_count, e.arrival_timestamp, -e.trip_departure_timestamp]}, lambda {|e| true})
      print_result(route, "LEAST_CONNECTIONS")
      if(has_short_transfers)
        route, has_short_transfers = compute_route(arrival_station, lambda  {|e| [e.connection_count, e.arrival_timestamp, -e.trip_departure_timestamp]}, lambda {|e| e.min_transfer_time > TRANSFER_TIME_THRESHOLD})
        print_result(route, "LEAST_CONNECTIONS_WITH_EASY_TRANSFERS")  
      end 
    end

    puts ""
    STDOUT.flush

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
