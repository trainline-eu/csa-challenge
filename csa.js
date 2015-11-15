//compile me with : java -jar node_modules\google-closure-compiler\compiler.jar --language_in=ECMASCRIPT6 --language_out=ES5 --js_output_file=out.js csa.js

var split = require('split');
var isTimetableLoaded = false;
var timeTable = [];
const MAX_STATIONS = 10;

  
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
                                                                arrivalTimestamp: request.departureTimestamp, 
                                                                connectionCount: 0, 
                                                                refersToTimetableIndex: NaN,
                                                                inConnection: null
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
          earliestArrivalMinConnections[connection.arrivalStation].push({departureStation:connection.departureStation, 
                                                                        arrivalTimestamp: connection.arrivalTimestamp, 
                                                                        connectionCount: value.connectionCount+1, 
                                                                        refersToTimetableIndex: indexOnTimetable,
                                                                        inConnection: value
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
  
  var selectedPossibility = null;
  for(var i = 0; i < possibilities.length; i++){
    if(possibilities[i].connectionCount === lastStep.connectionCount - 1){
      leastConnectionCount = possibilities[i].connectionCount;
      selectedPossibility = possibilities[i];
    }
  } 
  
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
  
function printResultEarliest(request, earliestArrivalMinConnections){

  var route = [];

  //find value for which arrivalTimestamp is minumum to get where to start.
  var possibilities = earliestArrivalMinConnections[request.arrivalStation];

  var LeastArrivalTimestamp = Infinity;
  var selectedPossibility = null;
  for(var i = 0; i < possibilities.length; i++){
    if(possibilities[i].arrivalTimestamp < LeastArrivalTimestamp){
      LeastArrivalTimestamp = possibilities[i].arrivalTimestamp;
      selectedPossibility = possibilities[i];
    }
  } 

  //While we didn't reach the destination, follow the node using the property inConnection
  while(selectedPossibility.inConnection != null){
    route.push(timeTable[selectedPossibility.refersToTimetableIndex]);
    selectedPossibility = selectedPossibility.inConnection;
  }

  route.reverse().forEach(function(connection){
    process.stderr.write("fastest route goes throug : " + connection.departureStation+" "+connection.arrivalStation+" "+connection.departureTimestamp+" "+connection.arrivalTimestamp +"\n");
    //solutionType 1 indicates fastest route
    console.log("1 "+connection.departureStation+" "+connection.arrivalStation+" "+connection.departureTimestamp+" "+connection.arrivalTimestamp );
  });
  
}


function printResultLeastConnections(request, earliestArrivalMinConnections){

  //for least ammount of connections, one has to start at the arrival, and follow the links towards the start.
  //TODO if several choices, criteria should help choosing. 
  route = [];
  var lastStep = {};

  //find value for which connectionCount is minumum to get where to start.
  var possibilities = earliestArrivalMinConnections[request.arrivalStation];

  var leastConnectionCount = Infinity;
  var selectedPossibility = null;
  for(var i = 0; i < possibilities.length; i++){
    if(possibilities[i].connectionCount < leastConnectionCount){
      leastConnectionCount = possibilities[i].connectionCount;
      selectedPossibility = possibilities[i];
    }
  } 

  route.push(timeTable[selectedPossibility.refersToTimetableIndex]);
  route = computeRouteLeastConnections(selectedPossibility, earliestArrivalMinConnections, route);

  route.reverse().forEach(function(connection){
    process.stderr.write("least connection route goes throug : " + connection.departureStation+" "+connection.arrivalStation+" "+connection.departureTimestamp+" "+connection.arrivalTimestamp +"\n");
    //solution type 2 indicates least connection number route
    console.log("2 "+connection.departureStation+" "+connection.arrivalStation+" "+connection.departureTimestamp+" "+connection.arrivalTimestamp );
  });  
}


//start looking what comes in from stdin
process.stdin.pipe(split()).on('data', processLine);
