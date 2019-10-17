//
//  JSONParser.swift
//  
//
//  Created by Robin Mayerhofer on 17.10.19.
//

import Foundation

open class JSONParser<T: Decodable>: JSONDecodableParser {

    public typealias OutputType = T

    required public init() {}

    public var jsonDecoder: JSONDecoder {
        return JSONDecoder()
    }

    public func parse(data: Data, encoding: String.Encoding) throws -> OutputType {
        return try jsonDecoder.decode(OutputType.self, from: data)
    }
}

open class JSONArrayParser<T: Decodable>: JSONParser<[T]> {}
