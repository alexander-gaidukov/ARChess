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
}

extension Message: Codable {
    
    enum CodngKeys: String, CodingKey {
        case type
    }
    
    func encode(to encoder: Encoder) throws {
        var containter = encoder.container(keyedBy: CodngKeys.self)
        switch self {
        case .iAMReady:
            try containter.encode("iAMReady", forKey: .type)
        case .gameBegins:
            try containter.encode("gameBegins", forKey: .type)
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
