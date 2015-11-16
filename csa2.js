//compile me with : java -jar node_modules\google-closure-compiler\compiler.jar --language_in=ECMASCRIPT6 --language_out=ES5 --js_output_file=out.js csa.js

var split = require('split');
var isTimetableLoaded = false;
var timeTable = [];
const MAX_STATIONS = 20;
const TRANSFER_TIME_THRESHOLD = 900; //15 minutes

  
//first we get the connextions from stdin, then an empty line, then one request at a time.
function processLine (line) { 
  if(line == ""){
    if(isTimetableLoaded){ //empty line after timetable is loaded is terminating signal.
      process.exit();
    }
    isTimetableLoaded = true;
    return;
  }
  if(!isTimetableLoaded){
    processConnection(line)
  }else{
    processRequest(line)
  }
}

function processConnection(line){
  var tokens = line.split(" ");
  timeTable.push({ 
    departureStation : parseInt(tokens[0]),
    arrivalStation : parseInt(tokens[1]),
    departureTimestamp : parseInt(tokens[2]),
    arrivalTimestamp : parseInt(tokens[3])
  });
}

function processRequest(line){
  var tokens = line.split(" ");
  var request = { 
    departureStation : parseInt(tokens[0]),
    arrivalStation : parseInt(tokens[1]),
    departureTimestamp : parseInt(tokens[2])
  };


  compute(request);

}

function compute(request){
  var earliestArrival = [];
  var earliestArrivalMinConnections = []; //intended to store a list of {departureStation, arrivalTimestamp, ConnectionCount, refersToTimetableIndex}

  //init inConnection and earliestArrival
  for(var i = 0; i < MAX_STATIONS ; i++){     
    earliestArrival[i] = Infinity;    
    earliestArrivalMinConnections[i] = [];
  }

  earliestArrival[request.departureStation] = request.departureTimestamp;
  earliestArrivalMinConnections[request.departureStation].push({departureStation:NaN, 
                                                                departureTimestamp:NaN,
                                                                arrivalTimestamp: request.departureTimestamp, 
                                                                connectionCount: -1, 
                                                                refersToTimetableIndex: NaN,
                                                                inConnection: null,
                                                                minimumTransferTime : Infinity
                                                              });

  //test if exceding MAX_STATIONS
  if(request.departureStation <= MAX_STATIONS && request.arrivalStation <= MAX_STATIONS){
    mainLoop(request, earliestArrivalMinConnections, earliestArrival);
  }

  //display the results
  if(hasSolutionOrReport(request, earliestArrivalMinConnections)){
    printResultEarliest(request, earliestArrivalMinConnections);
    printResultLeastConnections(request,earliestArrivalMinConnections);
    console.log("");//flush answer
  } 


}

function mainLoop(request, earliestArrivalMinConnections, earliestArrival){
  //loop with no optim what so ever.
  //we will store every possibility, options will be eliminated only after trying each timetable item.
  timeTable.forEach(function(connection, indexOnTimetable){
    //one can eliminate values if it departs too early
    //TODO : consider looking up earliestArrival based on data already present in earliestArrivalMinConnections. for space complexity optim at cost of time complexity
    if(connection.departureTimestamp >= earliestArrival[connection.departureStation]){//this connection can be used
      //update earliest arrival at station
      earliestArrival[connection.arrivalStation] = Math.min(connection.arrivalTimestamp, earliestArrival[connection.arrivalStation] ); 
      
      //for each value of earliestArrivalMinConnections[connection.departureStation], 
      earliestArrivalMinConnections[connection.departureStation].forEach(function(value, index){//TODO, what out for index ovverriden. might lead to trouble !
        //see if value.arrivalTimestamp < connection.departureTimestamp.
        //if it is the case, then, look up for the number of connection, 
        if(value.arrivalTimestamp < connection.departureTimestamp){
          //and append a new value to the array earliestArrivalMinConnections[connection.arrivalStation], incrementing the connectionCount
          //TODO : consider not adding if one already arrived at this station earlier with the same connection count, reduces computation and space cost of computeRouteLeastConnections function
          //TODO : consider making minimum transfer time station specific. If so, store a boolean and compare each time with the corresponding threshold
          earliestArrivalMinConnections[connection.arrivalStation].push({departureStation:connection.departureStation, 
                                                                        departureTimestamp:value.departureTimestamp ? value.departureTimestamp : connection.departureTimestamp,//TODO This repeats the information on every node. Consider adding it only to the node departing from origin
                                                                        arrivalTimestamp: connection.arrivalTimestamp, 
                                                                        connectionCount: value.connectionCount+1, 
                                                                        refersToTimetableIndex: indexOnTimetable,
                                                                        inConnection: value,
                                                                        minimumTransferTime: ( value.departureStation ? Math.min(value.minimumTransferTime, connection.departureTimestamp - value.arrivalTimestamp) : value.minimumTransferTime )
                                                                        //only consider it to be a transfer if previsous step is not the initial arrival
                                                                      });

        }
      });
    }
  });  
}


function computeRouteLeastConnections(lastStep, earliestArrivalMinConnections, route){
  //if lastStep is null, we have to base of the request
  //for each possible step at this station, look if we are done
  var possibilities = earliestArrivalMinConnections[lastStep.departureStation];
  
  var selectedPossibility = lastStep.inConnection;
  
  if(!selectedPossibility.refersToTimetableIndex){//found our starting point
    return route;
  }else{
    route.push(timeTable[selectedPossibility.refersToTimetableIndex]);
  }

  return computeRouteLeastConnections(selectedPossibility, earliestArrivalMinConnections, route);
}

function hasSolutionOrReport(request, earliestArrivalMinConnections){
   if(earliestArrivalMinConnections[request.arrivalStation].length == 0){
    console.log("NO_SOLUTION");
    process.stderr.write("NO_SOLUTION\n");
    return false;
  }else{
    return true;
  }
}


function orderStepsBy_EarliestArrival_LatestDeparture(a,b){
  if (a.arrivalTimestamp < b.arrivalTimestamp){
    return -1;
  }else if (a.arrivalTimestamp > b.arrivalTimestamp){
    return 1;
  }else{
    if (a.departureTimestamp > b.departureTimestamp){
      return -1;
    }else if (a.departureTimestamp < b.departureTimestamp){
      return 1;
    }
  }
  return 0;
}

function orderStepsBy_ConnectionCount_EarliestArrival_LatestDeparture(a,b){
  if (a.connectionCount < b.connectionCount){
    return -1;
  }else if (a.connectionCount > b.connectionCount){
    return 1;
  }else{
    if (a.arrivalTimestamp < b.arrivalTimestamp){
      return -1;
    }else if (a.arrivalTimestamp > b.arrivalTimestamp){
      return 1;
    }else{
      if (a.departureTimestamp > b.departureTimestamp){
        return -1;
      }else if (a.departureTimestamp < b.departureTimestamp){
        return 1;
      }
    }
  }
  return 0;
}
  
function printResultEarliest(request, earliestArrivalMinConnections){

  var route = [];

  //find value for which arrivalTimestamp is minumum to get where to start.
  var possibilities = earliestArrivalMinConnections[request.arrivalStation];

  possibilities = possibilities.sort(orderStepsBy_EarliestArrival_LatestDeparture);

  var selectedPossibility = possibilities[0];

  var routeHasShortTransferTime = selectedPossibility.minimumTransferTime < TRANSFER_TIME_THRESHOLD;

  //While we didn't reach the destination, follow the node using the property inConnection
  while(selectedPossibility.inConnection != null){
    route.push(timeTable[selectedPossibility.refersToTimetableIndex]);
    selectedPossibility = selectedPossibility.inConnection;
  }

  route.reverse().forEach(function(connection){
    process.stderr.write("EARLIEST_ARRIVAL : " + connection.departureStation+" "+connection.arrivalStation+" "+connection.departureTimestamp+" "+connection.arrivalTimestamp +"\n");
    //solutionType 1 indicates fastest route
    console.log("EARLIEST_ARRIVAL "+connection.departureStation+" "+connection.arrivalStation+" "+connection.departureTimestamp+" "+connection.arrivalTimestamp );
  });


  if(routeHasShortTransferTime){//compute an alternative route without short transfer.  
    route = [];
    selectedPossibility = null;
    for(var i = 0; i < possibilities.length; i++){
      if(possibilities[i].minimumTransferTime >= TRANSFER_TIME_THRESHOLD){
        selectedPossibility = possibilities[i];
        break;
      }
    } 

    if(selectedPossibility){ //It is possible there is no way to get all the transfers longer than the threshold
      //While we didn't reach the destination, follow the node using the property inConnection
      while(selectedPossibility.inConnection != null){
        route.push(timeTable[selectedPossibility.refersToTimetableIndex]);
        selectedPossibility = selectedPossibility.inConnection;
      }

      route.reverse().forEach(function(connection){
        process.stderr.write("EARLIEST_ARRIVAL_WITH_EASY_TRANSFERS : " + connection.departureStation+" "+connection.arrivalStation+" "+connection.departureTimestamp+" "+connection.arrivalTimestamp +"\n");
        //solutionType 1 indicates fastest route
        console.log("EARLIEST_ARRIVAL_WITH_EASY_TRANSFERS "+connection.departureStation+" "+connection.arrivalStation+" "+connection.departureTimestamp+" "+connection.arrivalTimestamp );
      });
    }
  }   
}


function printResultLeastConnections(request, earliestArrivalMinConnections){

  //for least ammount of connections, one has to start at the arrival, and follow the links towards the start.
  //TODO if several choices, criteria should help choosing. 
  route = [];

  //find value for which connectionCount is minumum to get where to start.
  var possibilities = earliestArrivalMinConnections[request.arrivalStation];

  possibilities = possibilities.sort(orderStepsBy_ConnectionCount_EarliestArrival_LatestDeparture);

  var selectedPossibility = possibilities[0];

  var routeHasShortTransferTime = selectedPossibility.minimumTransferTime < TRANSFER_TIME_THRESHOLD;

  route.push(timeTable[selectedPossibility.refersToTimetableIndex]);
  route = computeRouteLeastConnections(selectedPossibility, earliestArrivalMinConnections, route);

  route.reverse().forEach(function(connection){
    process.stderr.write("LEAST_CONNECTIONS " + connection.departureStation+" "+connection.arrivalStation+" "+connection.departureTimestamp+" "+connection.arrivalTimestamp +"\n");
    //solution type 2 indicates least connection number route
    console.log("LEAST_CONNECTIONS "+connection.departureStation+" "+connection.arrivalStation+" "+connection.departureTimestamp+" "+connection.arrivalTimestamp );
  });  

  if(routeHasShortTransferTime){//compute an alternative route without short transfer.

    route = [];
    selectedPossibility = null;

    for(var i = 0; i < possibilities.length; i++){
      if(possibilities[i].minimumTransferTime >= TRANSFER_TIME_THRESHOLD){
        selectedPossibility = possibilities[i];
        break;
      }
    }

    if(selectedPossibility){ //It is possible there is no way to get all the transfers longer than the threshold

      route.push(timeTable[selectedPossibility.refersToTimetableIndex]);
      route = computeRouteLeastConnections(selectedPossibility, earliestArrivalMinConnections, route);

      route.reverse().forEach(function(connection){
        process.stderr.write("LEAST_CONNECTIONS_WITH_EASY_TRANSFERS " + connection.departureStation+" "+connection.arrivalStation+" "+connection.departureTimestamp+" "+connection.arrivalTimestamp +"\n");
        //solution type 2 indicates least connection number route
        console.log("LEAST_CONNECTIONS_WITH_EASY_TRANSFERS "+connection.departureStation+" "+connection.arrivalStation+" "+connection.departureTimestamp+" "+connection.arrivalTimestamp );
      });  

    }




  } 

}


//start looking what comes in from stdin
process.stdin.pipe(split()).on('data', processLine);
