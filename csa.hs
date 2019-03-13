import System.IO
import qualified Data.Map as M
import Data.Maybe (fromMaybe, fromJust)
import Control.Applicative
import Control.Monad (unless)
import Numeric
import qualified Data.ByteString.Char8 as BS (ByteString, getLine, readInt, words, null)

readInts :: BS.ByteString -> [Int]
readInts = map (fst . fromJust . BS.readInt) . BS.words

type Station = Int

type Timestamp = Int

infinity :: Timestamp
infinity = maxBound

-- Evaluate Maybe Timestamp with infinity as fallback
timestamp :: Maybe Timestamp -> Timestamp
timestamp = fromMaybe infinity

-- Connection
-- departureStation arrivalStation departureTime arrivalTime
data Connection = Connection Station Station Timestamp Timestamp

newConnection :: [Int] -> Connection
newConnection [departure, arrival, departureTime, arrivalTime] =
        Connection departure arrival departureTime arrivalTime
newConnection _ = error "Illegal Connection values"

parseConnection :: BS.ByteString -> Connection
parseConnection = newConnection.readInts

printConnection :: Connection -> String
printConnection (Connection departure arrival departureTime arrivalTime) =
  unwords . map show $ [departure, arrival, departureTime, arrivalTime]

-- Query
-- departureStation arrivalStation departureTime
data Query = Query Station Station Timestamp

newQuery :: [Int] -> Query
newQuery [departure, arrival, departureTime] = Query departure arrival departureTime
newQuery _ = error "Illegal Query values"

parseQuery :: BS.ByteString -> Query
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
buildTimetable = (augmentTimetable infinity) .emptyTimetable

augmentTimetable :: Timestamp -> Timetable -> [Connection] -> Timetable
augmentTimetable _ timetable [] = timetable
augmentTimetable earliestArrival timetable@(Timetable arrivalTimes inConnections) (connection : connections) =
  let Connection departure arrival departureTime arrivalTime = connection
      bestDepartureTime = timestamp $ M.lookup departure arrivalTimes
      bestArrivalTime   = timestamp $ M.lookup arrival   arrivalTimes
  in
    if bestDepartureTime <= departureTime && bestArrivalTime > arrivalTime
    then
      let newArrivalTimes  = M.insert arrival arrivalTime arrivalTimes
          newInConnections = M.insert arrival connection  inConnections
          newTimetable     = Timetable newArrivalTimes newInConnections
      in augmentTimetable (min arrivalTime earliestArrival) newTimetable connections
    else
      if departureTime >= earliestArrival
      then
        timetable
      else
        augmentTimetable earliestArrival timetable connections

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

readConnections :: IO [BS.ByteString]
readConnections = do
  line <- BS.getLine
  if BS.null line
    then return []
    else (line :) <$> readConnections

printPath :: Path -> IO ()
printPath [] = putStrLn "NO_SOLUTION"
printPath path = mapM_ (putStrLn . printConnection) path

mainLoop :: [Connection] -> IO ()
mainLoop connections = do
  done <- isEOF
  unless done $ do
    line <- BS.getLine
    unless (BS.null line) $ do
      let query = parseQuery line
      let timetable = buildTimetable query connections

      printPath $ findPath timetable query
      putStrLn ""
      hFlush stdout

      mainLoop connections

-- main
main :: IO ()
main = do
  firstLines <- readConnections
  let connections = fmap parseConnection firstLines

  mainLoop connections
