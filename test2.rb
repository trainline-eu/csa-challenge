#!/usr/bin/env ruby

require 'test/unit'

if ARGV.size != 1
  puts "Usage: ruby #{$0} routing_executable"
  exit(-1)
end

EXECUTABLE = ARGV[0]

class TestCSA < Test::Unit::TestCase

  TIMETABLE =<<EOF
1 3 2000 10000
1 2 3600 7200
2 3 4000 5000
2 3 8000 9000
1 3 5000 10000
5 8 20000 25000
5 8 21000 25000
5 6 22000 23000
5 7 23000 23500
7 8 24000 25000
6 8 24000 25000
5 7 33100 33500
7 8 34000 35000
10 11 53000 54000
11 13 54500 58100
11 12 55000 56000
12 13 57000 58000

EOF

  def setup
    @io = IO.popen EXECUTABLE, "r+"

    @io.write TIMETABLE
  end

  def teardown
    @io.write "\n"
    @io.close
  end

  def read_answer(io)
    result = []
    line = io.gets.strip
    if line != "NO_SOLUTION"
      while !line.empty?
        tokens = line.split " "
        result << {
          :solution_type => tokens[0],
          :departure_station => tokens[1].to_i,
          :arrival_station => tokens[2].to_i,
          :departure_timestamp => tokens[3].to_i,
          :arrival_timestamp => tokens[4].to_i
        }

        line = io.gets.strip
      end
    end

    result
  end

  def test_simple_route
    puts "test_simple_route"
    @io.puts "1 2 3000"
    response = read_answer @io
    assert_equal 2, response.size
    assert_equal "EARLIEST_ARRIVAL", response[0][:solution_type]
    assert_equal 1, response[0][:departure_station]
    assert_equal 2, response[0][:arrival_station]
    assert_equal 3600, response[0][:departure_timestamp]
    assert_equal 7200, response[0][:arrival_timestamp]
    assert_equal "LEAST_CONNECTIONS", response[1][:solution_type]
    assert_equal 1, response[1][:departure_station]
    assert_equal 2, response[1][:arrival_station]
    assert_equal 3600, response[1][:departure_timestamp]
    assert_equal 7200, response[1][:arrival_timestamp]
  end

  def test_route_with_connection
    puts "test_route_with_connection"
    @io.puts "1 3 3000"
    response = read_answer @io
    assert_equal 4, response.size
    assert_equal "EARLIEST_ARRIVAL", response[0][:solution_type]
    assert_equal 1, response[0][:departure_station]
    assert_equal 2, response[0][:arrival_station]
    assert_equal 7200, response[0][:arrival_timestamp]
    assert_equal "EARLIEST_ARRIVAL", response[1][:solution_type]
    assert_equal 2, response[1][:departure_station]
    assert_equal 3, response[1][:arrival_station]
    assert_equal 9000, response[1][:arrival_timestamp]
    assert_equal "EARLIEST_ARRIVAL_WITH_EASY_TRANSFERS", response[2][:solution_type]
    assert_equal 1, response[2][:departure_station]
    assert_equal 3, response[2][:arrival_station]
    assert_equal 10000, response[2][:arrival_timestamp]
    assert_equal "LEAST_CONNECTIONS", response[3][:solution_type]
    assert_equal 1, response[3][:departure_station]
    assert_equal 3, response[3][:arrival_station]
    assert_equal 10000, response[3][:arrival_timestamp]
  end

  def test_later_departure
    puts "test_later_departure"
    @io.puts "1 3 4000"
    response = read_answer @io
    assert_equal 2, response.size
    assert_equal "EARLIEST_ARRIVAL", response[0][:solution_type]
    assert_equal 1, response[0][:departure_station]
    assert_equal 3, response[0][:arrival_station]
    assert_equal 10000, response[0][:arrival_timestamp]

    assert_equal "LEAST_CONNECTIONS", response[1][:solution_type]
    assert_equal 1, response[1][:departure_station]
    assert_equal 3, response[1][:arrival_station]
    assert_equal 10000, response[1][:arrival_timestamp]
  end

  def test_invalid_station
    puts "test_invalid_station"
    @io.puts "5 3 4000"
    response = read_answer @io
    assert_equal 0, response.size
  end

  def test_multiple_queries
    puts "test_multiple_queries"
    @io.puts "1 3 4000"
    response1 = read_answer @io
    @io.puts "1 3 4000"
    response2 = read_answer @io

    assert_equal 2, response1.size
    assert_equal 2, response2.size
  end

  def test_draw_elimination
    puts "test_draw_elimination"
    #both fastest and least connection may encounter draw solutions on this criteria, we need to filter out least worthy solutions.
    ###Fastest : 
    #1. find the solutions that arrive at the earliest possible date.
    #2. filter those that depart the latest.
    #3. choose any of these at random, no sepcified dehavior // too little chances we might end up with more than 1.
    ###Least COnnections :
    #0. find solutions with the least number of connections
    #1. filter the solutions that arrive at the earliest possible date.
    #2. filter those that depart the latest.
    #3. choose any of these at random, no sepcified dehavior // too little chances we might end up with more than 1.
    @io.puts "5 8 19000"
    response = read_answer @io
    assert_equal 5, response.size
    assert_equal "EARLIEST_ARRIVAL", response[0][:solution_type]
    assert_equal 5, response[0][:departure_station]
    assert_equal 7, response[0][:arrival_station]
    assert_equal 23500, response[0][:arrival_timestamp]
    assert_equal "EARLIEST_ARRIVAL", response[1][:solution_type]
    assert_equal 7, response[1][:departure_station]
    assert_equal 8, response[1][:arrival_station]
    assert_equal 25000, response[1][:arrival_timestamp]
    assert_equal "EARLIEST_ARRIVAL_WITH_EASY_TRANSFERS", response[2][:solution_type]
    assert_equal 5, response[2][:departure_station]
    assert_equal 6, response[2][:arrival_station]
    assert_equal 23000, response[2][:arrival_timestamp]
    assert_equal "EARLIEST_ARRIVAL_WITH_EASY_TRANSFERS", response[3][:solution_type]
    assert_equal 6, response[3][:departure_station]
    assert_equal 8, response[3][:arrival_station]
    assert_equal 25000, response[3][:arrival_timestamp]
    assert_equal "LEAST_CONNECTIONS", response[4][:solution_type]
    assert_equal 5, response[4][:departure_station]
    assert_equal 8, response[4][:arrival_station]
    assert_equal 21000, response[4][:departure_timestamp]
    assert_equal 25000, response[4][:arrival_timestamp]
  end

  def test_too_short_transfers_on_least_transfer_solution
    puts "test_too_short_transfers_on_least_transfer_solution"
    @io.puts "10 13 50000"
    response = read_answer @io
    assert_equal 8, response.size
    assert_equal "EARLIEST_ARRIVAL", response[0][:solution_type]
    assert_equal 10, response[0][:departure_station]
    assert_equal 11, response[0][:arrival_station]
    assert_equal 54000, response[0][:arrival_timestamp]
    assert_equal "EARLIEST_ARRIVAL", response[1][:solution_type]
    assert_equal 11, response[1][:departure_station]
    assert_equal 12, response[1][:arrival_station]
    assert_equal 56000, response[1][:arrival_timestamp]
    assert_equal "EARLIEST_ARRIVAL", response[2][:solution_type]
    assert_equal 12, response[2][:departure_station]
    assert_equal 13, response[2][:arrival_station]
    assert_equal 58000, response[2][:arrival_timestamp]
    assert_equal "LEAST_CONNECTIONS", response[3][:solution_type]
    assert_equal 10, response[3][:departure_station]
    assert_equal 11, response[3][:arrival_station]
    assert_equal 54000, response[3][:arrival_timestamp]
    assert_equal "LEAST_CONNECTIONS", response[4][:solution_type]
    assert_equal 11, response[4][:departure_station]
    assert_equal 13, response[4][:arrival_station]
    assert_equal 58100, response[4][:arrival_timestamp]
    assert_equal "LEAST_CONNECTIONS_WITH_EASY_TRANSFERS", response[5][:solution_type]
    assert_equal 10, response[5][:departure_station]
    assert_equal 11, response[5][:arrival_station]
    assert_equal 54000, response[5][:arrival_timestamp]
    assert_equal "LEAST_CONNECTIONS_WITH_EASY_TRANSFERS", response[6][:solution_type]
    assert_equal 11, response[6][:departure_station]
    assert_equal 12, response[6][:arrival_station]
    assert_equal 56000, response[6][:arrival_timestamp]
    assert_equal "LEAST_CONNECTIONS_WITH_EASY_TRANSFERS", response[7][:solution_type]
    assert_equal 12, response[7][:departure_station]
    assert_equal 13, response[7][:arrival_station]
    assert_equal 58000, response[7][:arrival_timestamp]
  end

end
