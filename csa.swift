import Foundation

typealias Station = Int

protocol InputType {
    func read(count: Int) throws -> [Int]?
}

struct Error: ErrorType {
    let message: String
    init(_ message: String) {
        self.message = message
    }
}

struct Connection {
    let from: Station, to: Station, departure: time_t, arrival: time_t
    
    init?(input: InputType) throws {
        guard let values = try input.read(4) else { return nil }
        from = values[0]
        to = values[1]
        departure = values[2]
        arrival = values[3]
        guard from >= 0 && to >= 0 else { throw Error("Station number cannot be negative.") }
        guard arrival >= departure else { throw Error("Time travel is not supported yet.") }
    }
}

struct Request {
    let from: Station, to: Station, departure: time_t

    init?(input: InputType) throws {
        guard let values = try input.read(3) else { return nil }
        from = values[0]
        to = values[1]
        departure = values[2]
        guard from >= 0 && to >= 0 else { throw Error("Station number cannot be negative.") }
    }
}

struct Router {
    private let connections: [Connection]
    private let count: Int
    
    init(input: InputType) throws {
        var connections: [Connection] = []
        while let connection = try Connection(input: input) {
            connections.append(connection)
        }
        self.connections = connections
        self.count = connections.reduce(0) { (count, connection) in
            max(count, connection.from + 1, connection.to + 1)
        }
    }
    
    func solve(request: Request) -> [Connection] {
        let from = request.from, to = request.to, departure = request.departure
        guard count > max(from, to) else { return [] }
        var incoming: [Connection?] = Array(count: count, repeatedValue: nil)
        for connection in connections {
            if connection.departure < departure || connection.to == from {
                continue
            }
            if let final = incoming[to] where connection.departure > final.arrival {
                break
            }
            if let current = incoming[connection.to] where connection.arrival > current.arrival {
                continue
            }
            if connection.from == from {
                incoming[connection.to] = connection
            } else if let previous = incoming[connection.from] where connection.departure > previous.arrival {
                incoming[connection.to] = connection
            }
        }
        var route: [Connection] = []
        var station = to
        while let connection = incoming[station] {
            route.insert(connection, atIndex: 0)
            station = connection.from
        }
        return route
    }
}

struct TextualInput: InputType {
    private let body: () -> String?
    
    init(_ body: () -> String?) {
        self.body = body
    }
    
    func read(count: Int) throws -> [Int]? {
        guard let line = body() else { return nil }
        guard !line.isEmpty else { return nil }
        let components = line.utf8.split(0x20)
        guard components.count == count else { throw Error("There should be exactly \(count) values on this line.") }
        return try components.map { component in
            guard let string = String(component), let integer = Int(string) else { throw Error("\"\(component)\" is not an integer.") }
            return integer
        }
    }
}

func printRoute<S: SequenceType where S.Generator.Element == Connection>(route: S) {
    for connection in route {
        print("\(connection.from) \(connection.to) \(connection.departure) \(connection.arrival)")
    }
    print("")
    fflush(stdout)
}

do {
    let input = TextualInput({ readLine() })
    let router = try Router(input: input)
    while let request = try Request(input: input) {
        let route = router.solve(request)
        printRoute(route)
    }
} catch let error as Error {
    fputs("\(error.message)\n", stderr)
    exit(1)
}
