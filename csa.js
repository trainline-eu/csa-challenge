#!/usr/bin/env node

'use strict'

const DEP = 0, ARR = 1, DEP_TS = 2, ARR_TS = 3
const MAX_STATION = 100000
const INFINITY = 1 << 30
const timetable = []

function compute(trip) {
  let earliestArr = new Array(MAX_STATION).fill(INFINITY)
  let inConn = []

  earliestArr[trip[DEP]] = trip[DEP_TS]

  for (let conn of timetable) {
    if (
      conn[DEP_TS] >= earliestArr[conn[DEP]] &&
      conn[ARR_TS] <  earliestArr[conn[ARR]]
    ) {
      inConn[conn[ARR]] = conn
      earliestArr[conn[ARR]] = conn[ARR_TS]
    } else if (conn[DEP_TS] >= earliestArr[trip[ARR]]) {
      break
    }
  }

  if (inConn[trip[ARR]] === undefined) {
    return null
  }

  let route = []
  let station = trip[ARR]
  while (station !== trip[DEP]) {
    route.unshift(inConn[station])
    station = inConn[station][DEP]
  }

  return route
}

let initializing = true
require('readline')
  .createInterface({ input: process.stdin })
  .on('line', function (line) {
    if (!line) {
      if (!initializing) {
        this.close()
      }
      initializing = false
      return
    }

    let connOrTrip = Uint32Array.from(line.split(' '))
    if (initializing) {
      timetable.push(connOrTrip)
    } else {
      let route = compute(connOrTrip)

      if (route) {
        console.log(route.map((c) => c.join(' ')).join('\n'), '\n')
      } else {
        console.log('NO_SOLUTION')
      }
    }
  })
