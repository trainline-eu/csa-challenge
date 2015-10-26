#!/usr/bin/env php
<?php

define('MAX_STATIONS', 100000);
define('DEPARTURE_STATION', 0);
define('ARRIVAL_STATION', 1);
define('DEPARTURE_TIME', 2);
define('ARRIVAL_TIME', 3);

function readTimetable($handle) {
	$result = array();
	while (($line = fgets($handle, 128)) !== false) {
		if ($line == "\n") {
			return $result;
		}
		$result[] = array_map('intval', explode(' ', $line));
	}
	return $result;
}

function compute(&$timetable, $departureStation, $arrivalStation, $departureTime) {
	$inConnection = array_fill(0, MAX_STATIONS, PHP_INT_MAX);
	$earliestArrival = array_fill(0, MAX_STATIONS, PHP_INT_MAX);

	$earliestArrival[$departureStation] = $departureTime;
	foreach ($timetable as $i => $connection) {
		if (
			$connection[DEPARTURE_TIME] >= $earliestArrival[$connection[DEPARTURE_STATION]] &&
			$connection[ARRIVAL_TIME] < $earliestArrival[$connection[ARRIVAL_STATION]]
		) {
			$inConnection[$connection[ARRIVAL_STATION]] = $i;
			$earliestArrival[$connection[ARRIVAL_STATION]] = $connection[ARRIVAL_TIME];
		}
	}

	if ($inConnection[$arrivalStation] === PHP_INT_MAX) {
		echo "NO_SOLUTION\n";
		return;
	}
	$route = [];
	$lastConnectionIndex = $inConnection[$arrivalStation];
	while ($lastConnectionIndex !== PHP_INT_MAX) {
		$connection = $timetable[$lastConnectionIndex];
		$route[] = $connection;
		$lastConnectionIndex = $inConnection[$connection[DEPARTURE_STATION]];
	} ;

	foreach (array_reverse($route) as $row) {
		printf("%d %d %d %d\n", $row[DEPARTURE_STATION], $row[ARRIVAL_STATION], $row[DEPARTURE_TIME], $row[ARRIVAL_TIME]);
	}
	echo "\n";
}

$fh = fopen('php://stdin', 'r');
$timetable = readTimetable($fh);

while (($line = fgets($fh, 128)) !== false) {
	if ($line !== "\n") {
		list($departureStation, $arrivalStation, $departureTime) = array_map('intval', explode(' ', $line));
		compute($timetable, $departureStation, $arrivalStation, $departureTime);
	}
}
