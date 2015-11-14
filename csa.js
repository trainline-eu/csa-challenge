//compile me with : java -jar node_modules\google-closure-compiler\compiler.jar --language_in=ECMASCRIPT6 --language_out=ES5 --js_output_file=out.js csa.js

var split = require('split');
var isTimetableLoaded = false;
var timeTable = [];
const MAX_STATIONS = 10;

  
//first we get the connextions from stdin, then an empty line, then one request at a time.
function processLine (line) { 
  if(line == ""){
    if(isTimetableLoaded){
      process.stderr.write("exiting\n");
      process.exit();
    }
    isTimetableLoaded = true;
    process.stderr.write("done with the timeTable, loaded : " + timeTable.length + "\n");
    return;
  }
  if(!isTimetableLoaded){
    processConnection(line)
  }else{
    processRequest(line)
  }
}

function processConnection(line){
  process.stderr.write("adding connection" + line + "\n");
  var tokens = line.split(" ");
  timeTable.push({ 
    departureStation : parseInt(tokens[0]),
    arrivalStation : parseInt(tokens[1]),
    departureTimestamp : parseInt(tokens[2]),
    arrivalTimestamp : parseInt(tokens[3])
  });
}

function processRequest(line){
  process.stderr.write("processing request" + line + "\n");
  var tokens = line.split(" ");
  var request = { 
    departureStation : parseInt(tokens[0]),
    arrivalStation : parseInt(tokens[1]),
    departureTimestamp : parseInt(tokens[2])
  };
  process.stderr.write("ready to compute request[" + request.departureStation + " " + request.arrivalStation + " " + request.departureTimestamp + "]\n");
  compute(request);

}

function compute(request){
  var inConnection = [];
  var earliestArrival = [];
  var earliestArrivalMinConnections = []; //intended to store a list of {departureStation, arrivalTimestamp, ConnectionCount, refersToTimetableIndex}

  process.stderr.write("computing a request from " + request.departureStation + "to " + request.arrivalStation + "at " + request.departureTimestamp + " and " + MAX_STATIONS +" stations\n");

  //init inConnection and earliestArrival
  for(var i = 0; i < MAX_STATIONS ; i++){
    inConnection[i] =  Infinity;         
    earliestArrival[i] = Infinity;    
    earliestArrivalMinConnections[i] = [];
  }

  earliestArrival[request.departureStation] = request.departureTimestamp;
  earliestArrivalMinConnections[request.departureStation].push({departureStation:NaN, 
                                                                arrivalTimestamp: request.departureTimestamp, 
                                                                connectionCount: 0, 
                                                                refersToTimetableIndex: NaN});

  //test if exceding MAX_STATIONS
  if(request.departureStation <= MAX_STATIONS && request.arrivalStation <= MAX_STATIONS){
    //mainLoop(request, inConnection, earliestArrival);
    mainLoop2(request, earliestArrivalMinConnections,earliestArrival);
  }

  //display the results 
  //printResult(request, inConnection, earliestArrival);
  printResult2(request,earliestArrivalMinConnections);

}

function mainLoop2(request, earliestArrivalMinConnections,earliestArrival){
  process.stderr.write("doing mainloop2 \n");
  //loop with no optim what so ever.
  //we will store every possibility, options will be eliminated only after trying everything.
  timeTable.forEach(function(connection, indexOnTimetable){
    process.stderr.write("processing index " + indexOnTimetable + "\n");
    //one can eliminate values if it departs too early
    if(connection.departureTimestamp >= earliestArrival[connection.departureStation]){
      process.stderr.write("Departure time is ok\n");
      //update earliest arrival at station.
      earliestArrival[connection.arrivalStation] = Math.min(earliestArrival[connection.arrivalStation], connection.arrivalTimestamp);
      //for each value of earliestArrivalMinConnections[connection.departureStation], 
      earliestArrivalMinConnections[connection.departureStation].forEach(function(value, index){//TODO, what out for index ovverriden. might lead to trouble !
        //see if value.arrivalTimestamp < connection.departureTimestamp.
        //if it is the case, then, look up for the number of connection, 
        process.stderr.write("Looking to previous step\n");
        if(value.arrivalTimestamp < connection.departureTimestamp){
          process.stderr.write("pushing a new step\n");
          //and append a new value to the array earliestArrivalMinConnections[connection.arrivalStation], incrementing the connectionCount
          //TODO : consider not adding if one already arrived at this station earlier with the same connection count.
          earliestArrivalMinConnections[connection.arrivalStation].push({departureStation:connection.departureStation, 
                                                                        arrivalTimestamp: connection.arrivalTimestamp, 
                                                                        connectionCount: value.connectionCount+1, 
                                                                        refersToTimetableIndex: indexOnTimetable});
        }
      });
    }
  });

  process.stderr.write("with earliestArrival = "+earliestArrival+" \n");
  process.stderr.write("with earliestArrivalMinConnections =  \n");
  for(var i = 0; i < MAX_STATIONS ; i++){
    process.stderr.write("      earliestArrivalMinConnections["+i+"] =  [");
    for(var j = 0; j < earliestArrivalMinConnections[i].length ; j++){
      process.stderr.write("{");
      process.stderr.write("departureStation:"+earliestArrivalMinConnections[i][j].departureStation+",");
      process.stderr.write("arrivalTimestamp:"+ earliestArrivalMinConnections[i][j].arrivalTimestamp+",");
      process.stderr.write("connectionCount:"+ earliestArrivalMinConnections[i][j].connectionCount+",");
      process.stderr.write("refersToTimetableIndex:"+ earliestArrivalMinConnections[i][j].refersToTimetableIndex+"");
      process.stderr.write("}");
    }
    process.stderr.write("]\n");
  }
  
}


function mainLoop(request, inConnection, earliestArrival){
  process.stderr.write("doing mainloop \n");
  var earliest = Infinity;
  timeTable.forEach(function(connection, index){
    process.stderr.write("looping at index "+index+"\n");
    process.stderr.write("connection.departureStation " + connection.departureStation+"\n");
    process.stderr.write("earliestArrival[connection.departureStation] " + earliestArrival[connection.departureStation]+"\n");
    if(connection.departureTimestamp >= earliestArrival[connection.departureStation] && connection.arrivalTimestamp < earliestArrival[connection.arrivalStation]){
      process.stderr.write("considering connection at index "+index+"\n");
      process.stderr.write("connection.arrivalTimestamp "+connection.arrivalTimestamp+" < earliestArrival[connection.arrivalStation]"+earliestArrival[connection.arrivalStation]+"\n");
      earliestArrival[connection.arrivalStation] = connection.arrivalTimestamp;
      process.stderr.write("saved arrival at station  "+connection.arrivalStation+" at "+connection.arrivalTimestamp+"\n");
      process.stderr.write("current earliestArrival = "+earliestArrival+" \n");
      inConnection[connection.arrivalStation] = index;
      if(connection.arrivalStation == request.arrivalStation){
        earliest = Math.min(earliest,connection.arrivalTimestamp)
        process.stderr.write("found arrival at index "+index+" and earliest = "+earliest+" \n");
      }
    }else if (connection.arrivalTimestamp > earliest){
      process.stderr.write("found slower path at index "+index+"\n");
      return
    }
  });

  process.stderr.write("with earliestArrival = "+earliestArrival+" \n");
  process.stderr.write("with inConnection = "+inConnection+" \n");
  
}

function printResult2(request, earliestArrivalMinConnections){

  if(earliestArrivalMinConnections[request.arrivalStation].length === 0){
    console.log("NO_SOLUTION");
    process.stderr.write("NO_SOLUTION\n");
  }else{
    //for least ammount of connections, one hase to start at the arrival, and follow the links towards the start.
    //if several choices, we will want to study both.
    route = [];
    var lastStep = {};

    process.stderr.write("printResult2\n");

    //find value for which connectionCount is minumum to get where to start.
    var possibilities = earliestArrivalMinConnections[request.arrivalStation];

    process.stderr.write("earliestArrivalMinConnections[request.arrivalStation] == "+earliestArrivalMinConnections[request.arrivalStation]+"\n");

    var leastConnectionCount = Infinity;
    var selectedPossibility = null;
    for(var i = 0; i < possibilities.length; i++){
      if(possibilities[i].connectionCount < leastConnectionCount){
        leastConnectionCount = possibilities[i].connectionCount;
        selectedPossibility = possibilities[i];
      }
    } 
  


  process.stderr.write("printresult2 selectedPossibility = "+ JSON.stringify(selectedPossibility)+"\n");

    route.push(timeTable[selectedPossibility.refersToTimetableIndex]);
  process.stderr.write("pushed "+ timeTable[selectedPossibility.refersToTimetableIndex]+"\n");

    route = computeRoutes(selectedPossibility, earliestArrivalMinConnections, route);


  process.stderr.write("printResult2 final route = "+ JSON.stringify(possibilities)+"\n");
    
    route.reverse().forEach(function(connection){
      process.stderr.write("route goes throug : " + connection.departureStation+" "+connection.arrivalStation+" "+connection.departureTimestamp+" "+connection.arrivalTimestamp +"\n");
      console.log("1 "+connection.departureStation+" "+connection.arrivalStation+" "+connection.departureTimestamp+" "+connection.arrivalTimestamp );
    });
    
    console.log("");
  }
  
}

function computeRoutes(lastStep, earliestArrivalMinConnections, route){
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


  process.stderr.write("computeRoutes selectedPossibility = "+ JSON.stringify(selectedPossibility)+"\n");

 

  if(!selectedPossibility.refersToTimetableIndex){//found our starting point
    process.stderr.write("found starting point\n");

    return route;
  }else{
     route.push(timeTable[selectedPossibility.refersToTimetableIndex]);
  process.stderr.write("pushed "+ timeTable[selectedPossibility.refersToTimetableIndex]+"\n");
  }


  return computeRoutes(selectedPossibility, earliestArrivalMinConnections, route);
}



function printResult(request, inConnection, earliestArrival){


  process.stderr.write("printing results \n");
  process.stderr.write("with earliestArrival = "+earliestArrival+" \n");
  process.stderr.write("with inConnection = "+inConnection+" \n");

  if(inConnection[request.arrivalStation] == Infinity){
    console.log("NO_SOLUTION");
    process.stderr.write("NO_SOLUTION\n");
  }else{
    route = [];
    var lastConnectionIndex = inConnection[request.arrivalStation];
    while(lastConnectionIndex != Infinity){
      var connection = timeTable[lastConnectionIndex];
      route.push(connection);
      lastConnectionIndex = inConnection[connection.departureStation];
    }
    route.reverse().forEach(function(connection){
      process.stderr.write("route goes throug : " + connection.departureStation+" "+connection.arrivalStation+" "+connection.departureTimestamp+" "+connection.arrivalTimestamp +"\n");
      console.log("1 "+connection.departureStation+" "+connection.arrivalStation+" "+connection.departureTimestamp+" "+connection.arrivalTimestamp );
    });
    console.log("");
  }
  
}






process.stdin.pipe(split()).on('data', processLine)
