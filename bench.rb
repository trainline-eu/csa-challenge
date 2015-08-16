#!/usr/bin/env ruby

require "zlib"

if ARGV.size != 1
  puts "Usage: ruby #{$0} routing_executable"
  exit(-1)
end

def consume_answer(io)
  line = io.gets.strip
  if line != "NO_SOLUTION"
    while !line.empty?
      line = io.gets.strip
    end
  end
end


puts "Loading top stations"
top_stations = File.open("stations").map { |id| id.to_i }
puts "… done\n\n"

puts "Starting the application"
io = IO.popen ARGV[0], "r+"
puts "… done\n\n"

puts "Loading the data"
Zlib::GzipReader::open("bench_data_48h.gz").each { |line| io.write line }
io.write "\n"
puts "… done\n\n"

puts "Starting the benchmark"
count = 0
start_time = Time.now

top_stations.each do |station|
  io.puts "#{station} #{top_stations.first} 0"
  consume_answer io
  count += 1
end

io.write "\n"
duration = Time.now - start_time
puts "… done\n\n"
puts "Total time: #{duration} seconds"
puts "Average time per search: #{duration * 1000 / count} ms"

begin
    io.close
rescue Errno::EPIPE
    # Prevent broken pipe errors
end
