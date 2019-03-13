#!/usr/local/bin/luajit
function main()
  -- Load data
  connections = {}
  for line in io.lines() do
    if line == "" then break end
    for value in string.gmatch(line, "%d+") do
      connections[#connections+1] = tonumber(value)
    end
  end
  -- Load queries
  in_conn = {}
  earliest_arr = {}
  for departure, arrival, departure_time in io.input():lines("*n", "*n", "*n") do
    for i = 1, MAX_STATION do
      in_conn[i] = INFINITY
      earliest_arr[i] = INFINITY
    end
    earliest_arr[departure] = departure_time
    if departure <= MAX_STATION and arrival <= MAX_STATION then
      find(connections, earliest_arr, in_conn, arrival)
    end
    print_result(connections, earliest_arr, in_conn, arrival)
  end
end

MAX_STATION = 100000
INFINITY = 16777216 --math.maxinteger (Lua 5.3)
function find(connections, earliest_arr, in_conn,  arr)
  earliest = INFINITY
  for i = 1, #connections, 4 do
    -- connection departure / arrival stations and time
    cds = connections[i]
    cas = connections[i + 1]
    cdt = connections[i + 2]
    cat = connections[i + 3]
    if cdt >= earliest_arr[cds] and cat < earliest_arr[cas] then
      earliest_arr[cas] = cat
      in_conn[cas] = i
      if cas == arr then
        earliest = math.min(earliest, cat)
      end
    elseif cdt >= earliest then
      return
    end
  end
end

function print_result(connections, earliest_arr, in_conn, arr)
  if in_conn[arr] == INFINITY then
    print("NO_SOLUTION")
  else
    route = {}
    last_conn_i = in_conn[arr]
    while last_conn_i ~= INFINITY do
      route[#route+1] = last_conn_i
      cds = connections[last_conn_i]
      last_conn_i = in_conn[cds]
    end
    -- The route goes from the arrival to the departure.
    rev_route = {}
    for i = 1, #route do
      rev_route[#rev_route+1] = route[#route - i + 1]
    end
    -- Print it.
    for i = 1, #rev_route do
      conn_i = rev_route[i]
      -- Departure station, arrival station, departure time, arrival time.
      print(connections[conn_i] .. " " .. connections[conn_i+1] .. " " ..
        connections[conn_i+2] .. " " .. connections[conn_i+3])
    end
  end
  print()
  io.flush()
end

main()
