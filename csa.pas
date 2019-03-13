program csa;
{$mode objfpc}
uses
  Math, SysUtils, Classes;

const
  MAX_STATIONS = 100000;
  INFINITY = 4294967295;

type
  TConnection = record
    departureStation: Longword;
    arrivalStation: Longword;
    departureTime: Longword;
    arrivalTime: Longword;
  end;
  TTimetable = array of TConnection;
  TMyArray = array[0..MAX_STATIONS] of Longword;

var
  stdin, stdout: text;
  i: Longword;
  max: Longword;
  line: string;
  fields: TStringList;
  connection: TConnection;
  timetable: TTimetable;
  inConnection: TMyArray;
  earliestArrival: TMyArray;

procedure mainLoop(arrivalStation: Longword);
var
  earliest: Longword;
begin
  earliest := INFINITY;
  for i := 0 to max-1 do
  begin
    if (timetable[i].departureTime >= earliestArrival[timetable[i].departureStation]) AND (timetable[i].arrivalTime < earliestArrival[timetable[i].arrivalStation]) then
    begin
      earliestArrival[timetable[i].arrivalStation] := timetable[i].arrivalTime;
      inConnection[timetable[i].arrivalStation] := i;
      if (timetable[i].arrivalStation = arrivalStation) then
        earliest := min(timetable[i].arrivalTime, earliest);
    end
    else if (timetable[i].departureTime >= earliest) then
      Exit;
  end;
end;

procedure printResult(arrivalStation: Longword);
var
  lastConnectionIndex: Longword;
  route: TTimetable;
  maxRoute: Longword;
begin
  if inConnection[arrivalStation] = INFINITY then
  begin
    WriteLn(stdout, 'NO_SOLUTION');
  end
  else
  begin
    lastConnectionIndex := inConnection[arrivalStation];
    i := 0;
    while (lastConnectionIndex <> INFINITY) do
    begin
      connection := timetable[lastConnectionIndex];
      lastConnectionIndex := inConnection[connection.departureStation];
      SetLength(route, i+1);
      route[i] := connection;
      i := i + 1;
    end;
    maxRoute := i;
    for i := maxRoute-1 downto 0 do
      WriteLn(stdout, route[i].departureStation, ' ', route[i].arrivalStation, ' ', route[i].departureTime, ' ', route[i].arrivalTime);
  end;
  WriteLn(stdout, '');
  Flush(stdout);
end;

procedure compute(departureStation, arrivalStation, departureTime: Longword);
begin
  FillDWord(inConnection, MAX_STATIONS, INFINITY);
  FillDWord(earliestArrival, MAX_STATIONS, INFINITY);
  earliestArrival[departureStation] := departureTime;

  if (departureStation <= MAX_STATIONS) AND (arrivalStation <= MAX_STATIONS) then
    mainLoop(arrivalStation);
  printResult(arrivalStation);
end;

begin
  assign(stdin, '');
  assign(stdout, '');
  reset(stdin);
  rewrite(stdout);
  fields := TStringList.Create;
  fields.Delimiter := ' ';
  i := 0;
  while not eof(stdin) do
  begin
    ReadLn(stdin, line);
    if (line = '') then
      break;
    fields.DelimitedText := line;
    connection.departureStation := StrToInt(fields[0]);
    connection.arrivalStation := StrToInt(fields[1]);
    connection.departureTime := StrToInt(fields[2]);
    connection.arrivalTime := StrToInt(fields[3]);
    SetLength(timetable, i+1);
    timetable[i] := connection;
    i := i + 1;
  end;
  max := i;
  while not eof(stdin) do
  begin
    ReadLn(stdin, line);
    if (line = '') then
      continue;
    fields.DelimitedText := line;
    connection.departureStation := StrToInt(fields[0]);
    connection.arrivalStation := StrToInt(fields[1]);
    connection.departureTime := StrToInt(fields[2]);
    compute(connection.departureStation, connection.arrivalStation, connection.departureTime);
  end;
  Close(stdin);
  Close(stdout);
end.
