//
//  File.swift
//  Chess
//
//  Created by Alexandr Gaidukov on 21.04.2020.
//  Copyright © 2020 Alexaner Gaidukov. All rights reserved.
//

import Foundation

enum Message {
    case iAMReady
    case gameBegins
    case move(SIMD2<Int>, SIMD2<Int>)
}

extension Message: Codable {
    
    enum CodngKeys: String, CodingKey {
        case type
        case startRow
        case startColumn
        case endRow
        case endColumn
    }
    
    func encode(to encoder: Encoder) throws {
        var containter = encoder.container(keyedBy: CodngKeys.self)
        switch self {
        case .iAMReady:
            try containter.encode("iAMReady", forKey: .type)
        case .gameBegins:
            try containter.encode("gameBegins", forKey: .type)
        case let .move(start, end):
            try containter.encode("move", forKey: .type)
            try containter.encode(start[0], forKey: .startRow)
            try containter.encode(start[1], forKey: .startColumn)
            try containter.encode(end[0], forKey: .endRow)
            try containter.encode(end[1], forKey: .endColumn)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try! decoder.container(keyedBy: CodngKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "iAMReady":
            self = .iAMReady
        case "gameBegins":
            self = .gameBegins
        case "move":
            let startRow = try container.decode(Int.self, forKey: .startRow)
            let startColumn = try container.decode(Int.self, forKey: .startColumn)
            let endRow = try container.decode(Int.self, forKey: .endRow)
            let endColumn = try container.decode(Int.self, forKey: .endColumn)
            self = .move([startRow, startColumn], [endRow, endColumn])
        default:
            fatalError()
        }
    }
}

extension Message {
    var data: Data {
        try! JSONEncoder().encode(self)
    }
}
