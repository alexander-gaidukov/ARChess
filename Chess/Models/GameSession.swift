//
//  Session.swift
//  Chess
//
//  Created by Alexandr Gaidukov on 19.04.2020.
//  Copyright © 2020 Alexaner Gaidukov. All rights reserved.
//

import MultipeerConnectivity

final class GameSession {
    static let shared: GameSession = GameSession()
    private init() {}
    var isHost: Bool = false
    var mcSession: MCSession?
}
