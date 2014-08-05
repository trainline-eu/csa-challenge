import System.IO
import qualified Data.Map as M
import Data.Maybe (fromMaybe)

readInts :: String -> [Integer]
readInts = map read . words

type Station = Integer

type Timestamp = Integer

infinity :: Timestamp
infinity = 10000000000000000000000000 -- Infinite timestamp should be that high

-- Evaluate Maybe Timestamp with infinity as fallback
timestamp :: Maybe Timestamp -> Timestamp
timestamp = fromMaybe infinity

-- Connection
-- departureStation arrivalStation departureTime arrivalTime
data Connection = Connection Station Station Timestamp Timestamp

newConnection :: [Integer] -> Connection
newConnection [departure, arrival, departureTime, arrivalTime] =
        Connection departure arrival departureTime arrivalTime
newConnection _ = error "Illegal Connection values"

parseConnection :: String -> Connection
parseConnection = newConnection.readInts

printConnection :: Connection -> String
printConnection (Connection departure arrival departureTime arrivalTime) =
  unwords . map show $ [departure, arrival, departureTime, arrivalTime]

-- Query
-- departureStation arrivalStation departureTime
data Query = Query Station Station Timestamp

newQuery :: [Integer] -> Query
newQuery [departure, arrival, departureTime] = Query departure arrival departureTime
newQuery _ = error "Illegal Query values"

parseQuery :: String -> Query
parseQuery = newQuery.readInts

-- Timetable
-- arrivalTimes inConnections
data Timetable = Timetable IndexedTimestamps IndexedConnections

type IndexedTimestamps  = M.Map Station Timestamp
type IndexedConnections = M.Map Station Connection

emptyTimetable :: Query -> Timetable
emptyTimetable (Query departure _ departureTime) =
  Timetable (M.insert departure departureTime M.empty) M.empty

buildTimetable :: Query -> [Connection] -> Timetable
buildTimetable = augmentTimetable.emptyTimetable

augmentTimetable :: Timetable -> [Connection] -> Timetable
augmentTimetable timetable [] = timetable
augmentTimetable timetable@(Timetable arrivalTimes inConnections) (connection : connections) =
  let Connection departure arrival departureTime arrivalTime = connection
      bestDepartureTime = timestamp $ M.lookup departure arrivalTimes
      bestArrivalTime   = timestamp $ M.lookup arrival   arrivalTimes
  in
    if bestDepartureTime <= departureTime && bestArrivalTime > arrivalTime
    then
      let newArrivalTimes  = M.insert arrival arrivalTime arrivalTimes
          newInConnections = M.insert arrival connection  inConnections
          newTimetable     = Timetable newArrivalTimes newInConnections
      in augmentTimetable newTimetable connections
    else
      augmentTimetable timetable connections

-- CSA implementation
findPath :: Timetable -> Query -> Path
findPath (Timetable _ inConnections) (Query _ arrival _) = findPathImpl inConnections arrival []

type Path = [Connection]

findPathImpl :: IndexedConnections -> Station -> [Connection] -> [Connection]
findPathImpl inConnections objective accumulator =
  case M.lookup objective inConnections of
    Nothing         -> accumulator
    Just connection ->
      let Connection departure _ _ _ = connection
      in findPathImpl inConnections departure (connection : accumulator)

-- main
main :: IO ()
main = do
  input <- fmap lines getContents

  let connections = map parseConnection . takeWhile (not.null) $ input
      query       = parseQuery . head . dropWhile null . dropWhile (not.null) $ input
      timetable   = buildTimetable query connections

  case findPath timetable query of
    []   -> putStrLn "NO_SOLUTION"
    path -> mapM_ (putStrLn . printConnection) path

  putStrLn ""
