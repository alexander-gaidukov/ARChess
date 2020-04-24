//
//  File.swift
//  Chess
//
//  Created by Alexandr Gaidukov on 21.04.2020.
//  Copyright © 2020 Alexaner Gaidukov. All rights reserved.
//

import Foundation
import simd

extension simd_float4x4 {
    var toArray: [Float] {
        let c = columns
        return [c.0, c.1, c.2, c.3].flatMap { [ $0.x, $0.y, $0.z, $0.w ] }
    }
    
    init(_ array: [Float]) {
        var columns: [SIMD4<Float>] = []
        for i in 0..<3 {
            columns.append(SIMD4<Float>(array[i * 4..<(i + 1)*4]))
        }
        self.init(columns)
    }
}

enum Message {
    case iAMReady
    case gameBegins(FigureColor, float4x4)
    case move(SIMD2<Int>, SIMD2<Int>)
}

extension Message: Codable {
    
    enum CodngKeys: String, CodingKey {
        case type
        case color
        case transform
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
        case let .gameBegins(color, transform):
            try containter.encode("gameBegins", forKey: .type)
            try containter.encode(color, forKey: .color)
            try containter.encode(transform.toArray, forKey: .transform)
        case let .move(start, end):
            try containter.encode("move", forKey: .type)
            try containter.encode(start[0], forKey: .startRow)
            try containter.encode(start[1], forKey: .startColumn)
            try containter.encode(end[0], forKey: .endRow)
            try containter.encode(end[1], forKey: .endColumn)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodngKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "iAMReady":
            self = .iAMReady
        case "gameBegins":
            let color = try container.decode(FigureColor.self, forKey: .color)
            let transform = float4x4(try container.decode([Float].self, forKey: .transform))
            self = .gameBegins(color, transform)
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
