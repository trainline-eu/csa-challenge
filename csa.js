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
    departureStation : tokens[0],
    arrivalStation : tokens[1],
    departureTimestamp : tokens[2],
    arrivalTimestamp : tokens[3]
  });
}

function processRequest(line){
  process.stderr.write("processing request" + line + "\n");
  var tokens = line.split(" ");
  var request = { 
    departureStation : tokens[0],
    arrivalStation : tokens[1],
    departureTimestamp : tokens[2]
  };
  process.stderr.write("ready to compute request[" + request.departureStation + " " + request.arrivalStation + " " + request.departureTimestamp + "]\n");
  compute(request);

}

function compute(request){
  var inConnection = [];
  var earliestArrival = [];

  process.stderr.write("computing a request from " + request.departureStation + "to " + request.arrivalStation + "at " + request.departureTimestamp + " and " + MAX_STATIONS +" stations\n");

  //init inConnection and earliestArrival
  for(var i = 0; i < MAX_STATIONS ; i++){
    inConnection[i] =  Infinity;         
    earliestArrival[i] = Infinity;         
  }

  earliestArrival[request.departureStation] = request.departureTimestamp;

  //test if exceding MAX_STATIONS
  if(request.departureStation <= MAX_STATIONS && request.arrivalStation <= MAX_STATIONS){
    mainLoop(request, inConnection, earliestArrival);
  }

  //display the results 
  printResult(request, inConnection, earliestArrival);

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
      earliestArrival[connection.arrivalStation] = connection.arrivalTimestamp;
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
      console.log(""+connection.departureStation+" "+connection.arrivalStation+" "+connection.departureTimestamp+" "+connection.arrivalTimestamp + "\n");
    });
  }
  
}






process.stdin.pipe(split()).on('data', processLine)
