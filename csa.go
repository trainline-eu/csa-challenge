// gofmt -w=true *.go && go build -o csa-go csa.go && ruby test.rb ./csa-go

package main

import (
	"bufio"
	"fmt"
	"math"
	"os"
)

const maxStations = 100000
const infinity = math.MaxUint32

type Connection struct {
	departureStation uint32
	arrivalStation   uint32
	departureTime    uint32
	arrivalTime      uint32
}

type Timetable []Connection

func readTimetable(scanner *bufio.Scanner) Timetable {
	timetable := make([]Connection, 0)

	for scanner.Scan() {
		if len(scanner.Text()) == 0 {
			break
		} else {
			connection := Connection{}
			_, err := fmt.Sscanln(
				scanner.Text(),
				&connection.departureStation,
				&connection.arrivalStation,
				&connection.departureTime,
				&connection.arrivalTime)
			if err != nil {
				panic(err)
			}
			timetable = append(timetable, connection)
		}
	}

	return timetable
}

func (timetable Timetable) compute(departureStation uint32, arrivalStation uint32, departureTime uint32) {
	// initialization
	inConnection := make([]uint32, maxStations, maxStations)
	earliestArrival := make([]uint32, maxStations, maxStations)

	for i := 0; i < maxStations; i++ {
		inConnection[i] = infinity
		earliestArrival[i] = infinity
	}

	// main loop
	earliestArrival[departureStation] = departureTime
	for i, connection := range timetable {
		if connection.departureTime >= earliestArrival[connection.departureStation] &&
			connection.arrivalTime < earliestArrival[connection.arrivalStation] {

			inConnection[connection.arrivalStation] = uint32(i)
			earliestArrival[connection.arrivalStation] = connection.arrivalTime
		}
	}

	// print result
	if inConnection[arrivalStation] == infinity {
		fmt.Println("NO_SOLUTION")
	} else {
		route := make([]Connection, 0)

		for lastConnectionIndex := inConnection[arrivalStation]; lastConnectionIndex != infinity; {
			connection := timetable[lastConnectionIndex]
			route = append(route, connection)
			lastConnectionIndex = inConnection[connection.departureStation]
		}

		for i := len(route) - 1; i >= 0; i-- {
			fmt.Printf("%d %d %d %d\n", route[i].departureStation, route[i].arrivalStation, route[i].departureTime, route[i].arrivalTime)
		}

		fmt.Println("")
	}

}

func main() {
	scanner := bufio.NewScanner(os.Stdin)

	timetable := readTimetable(scanner)

	var departureStation, arrivalStation, departureTime uint32
	for scanner.Scan() {
		if len(scanner.Text()) == 0 {
			os.Exit(0)
		} else {
			_, err := fmt.Sscanln(scanner.Text(), &departureStation, &arrivalStation, &departureTime)
			if err != nil {
				panic(err)
			}
			timetable.compute(departureStation, arrivalStation, departureTime)
		}
	}
}
