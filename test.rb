#!/usr/bin/env ruby

require 'open3'
require 'test/unit/assertions'
extend Test::Unit::Assertions

TIMETABLE =<<EOF
1 3 2000 10000
1 2 3600 7200
2 3 4000 5000
2 3 8000 9000
1 3 5000 10000

EOF

def read_answer io
    result = []
    line = io.gets.strip
    if line != "NO_SOLUTION"
        while !line.empty?
            tokens = line.split " "
            result << {
                :departure_station => tokens[0].to_i,
                :arrival_station => tokens[1].to_i,
                :departure_timestamp => tokens[2].to_i,
                :arrival_timestamp => tokens[3].to_i,
            }

            line = io.gets.strip
        end
    end

    result
end

def run_tests program
    stdin, stdout = Open3.popen2 program

    stdin.write TIMETABLE

    stdin.write "1 2 3000\n"
    response = read_answer stdout
    assert_equal 1, response.size
    assert_equal 1, response[0][:departure_station]
    assert_equal 2, response[0][:arrival_station]
    assert_equal 3600, response[0][:departure_timestamp]
    assert_equal 7200, response[0][:arrival_timestamp]

    stdin.write "1 3 3000\n"
    response = read_answer stdout
    assert_equal 2, response.size
    assert_equal 1, response[0][:departure_station]
    assert_equal 2, response[0][:arrival_station]
    assert_equal 7200, response[0][:arrival_timestamp]
    assert_equal 2, response[1][:departure_station]
    assert_equal 3, response[1][:arrival_station]
    assert_equal 9000, response[1][:arrival_timestamp]

    stdin.write "1 3 4000\n"
    response = read_answer stdout
    assert_equal 1, response.size
    assert_equal 1, response[0][:departure_station]
    assert_equal 3, response[0][:arrival_station]
    assert_equal 10000, response[0][:arrival_timestamp]

    stdin.write "5 3 4000\n"
    response = read_answer stdout
    assert_equal 0, response.size


    stdin.write "\n"
    stdin.close
    stdout.close

    puts "Everything seems to work fine!"
end

if ARGV.size != 1
    puts "Usage: #{$0} routing_executable"
else
    run_tests ARGV[0]
end
