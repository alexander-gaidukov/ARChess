//
//  GameCoordinator.swift
//  Chess
//
//  Created by Alexandr Gaidukov on 13.04.2020.
//  Copyright © 2020 Alexaner Gaidukov. All rights reserved.
//

import Foundation
import Combine

enum MoveResult {
    case success(MateType, SIMD2<Int>, [SIMD2<Int>]?, Figure?)
    case failure(SIMD2<Int>?)
}

enum GameResult {
    case draw
    case win(FigureColor)
}

enum GameState: Equatable {
    case initCoaching
    case planeSearching
    case waitingForTheHostGame
    case waitingForGameElements
    case positioning
    case scaling
    case waitingForTheOtherPlayer
    case playing
}

extension GameState {
    var message: String? {
        switch self {
        case .initCoaching:
            return nil
        case .planeSearching:
            return "Click on a horizontal surface to place the board"
        case .waitingForTheHostGame:
            return "Waiting while the host place the board"
        case .waitingForGameElements:
            return "Game elements loading..."
        case .positioning:
            return nil
        case .scaling:
            return "Use gestures to position and scale board, then tap Start button"
        case .playing:
            return nil
        case .waitingForTheOtherPlayer:
            return "Waiting for the other player"
        }
    }
}

final class GameCoordinator: ObservableObject {
    
    var board: GameBoard = GameBoard()
    
    var gameSession: GameSession {
        GameSession.shared
    }
    
    var playerColor: FigureColor = GameSession.shared.isHost ? .white : .black
    
    var isSecondPlayerReady: Bool = false {
        didSet {
            DispatchQueue.main.async {
                if self.state == .waitingForTheOtherPlayer {
                    self.state = .playing
                }
            }
        }
    }
    
    @Published var activeColor: FigureColor = .white
    @Published var killedFigures:[Figure] = []
    @Published var state: GameState = .initCoaching
    @Published var askForTransformation: Bool = false
    @Published var mateType: MateType = .not
    @Published var oponentDidLeaveTheGame: Bool = false
    
    var figureTransformationCompletion: ((FigureType) -> ())?
    
    var infoMessage: String? {
        guard case .playing = state else {
            return state.message
        }
        
        switch mateType {
        case .not, .check:
            return activeColor == .white ? "White move" : "Black move"
        case .mate(let color, _):
            return color == .white ? "Black won!" : "White won!"
        case .stalemate, .draw:
            return "Draw"
        }
    }
    
    var startButtonVisible: Bool {
        state == .scaling
    }
    
    var whiteKilledFigures: [Figure] {
        killedFigures.filter { $0.color == .white }.sorted()
    }
    
    var blackKilledFigures: [Figure] {
        killedFigures.filter { $0.color == .black }.sorted()
    }
    
    func oponentLeaveTheGame() {
        oponentDidLeaveTheGame = true
    }
    
    func quitTheGame() {
        gameSession.mcSession.delegate = nil
        gameSession.mcSession.disconnect()
    }
    
    func startGame() {
        guard state != .playing else { return }
        if gameSession.isHost {
            state = isSecondPlayerReady ? .playing : .waitingForTheOtherPlayer
        } else {
            state = .waitingForTheOtherPlayer
            sendMessage(.iAMReady)
        }
    }
    
    func sendMessage(_ message: Message) {
        try? gameSession.mcSession.send(message.data, toPeers: gameSession.mcSession.connectedPeers, with: .reliable)
    }
    
    func move(figure: Figure, from start: SIMD2<Int>, to end: SIMD2<Int>, completion: @escaping (MoveResult) -> ()) {
        guard figure.color == activeColor else {
            completion(.failure(nil))
            return
        }
        guard let boardFigure = board[start], boardFigure.type == figure.type, boardFigure.color == figure.color else { fatalError() }
        guard board.isAvailableMove(from: start, to: end) else {
            completion(.failure(nil))
            return
        }
        
        var newBoard = board.makingMove(from: start, to: end)
        if let pos = newBoard.check(color: boardFigure.color) {
            completion(.failure(boardFigure.type == .king ? pos : board.kingPosition(color: boardFigure.color)))
            return
        }
        
        if let killedFigure = board[end] {
            killedFigures.append(killedFigure)
        }
        
        var positionToEat: SIMD2<Int>? = nil
        if boardFigure.type == .pawn, start[1] != end[1], board[end] == nil {
            // we are ate on a bitten field
            if boardFigure.color == .white {
                positionToEat = [end[0] - 1, end[1]]
            } else {
                positionToEat = [end[0] + 1, end[1]]
            }
        }
        
        var additionalMove: [SIMD2<Int>]? = nil
        if figure.type == .king && abs(start[1] - end[1]) == 2 {
            if end[1] > start[1] {
                let sp: SIMD2<Int> = [start[0], board.size - 1]
                let ep: SIMD2<Int> = [start[0], end[1] - 1]
                additionalMove = [sp, ep]
            } else {
                let sp: SIMD2<Int> = [start[0], 0]
                let ep: SIMD2<Int> = [start[0], end[1] + 1]
                additionalMove = [sp, ep]
            }
        }
        
        if figure.type == .pawn && (end[0] == 0 || end[0] == board.size - 1) {
            figureTransformationCompletion = { [weak self] figureType in
                guard let self = self else { return }
                let transformedFigure = Figure(type: figureType, color: figure.color)
                newBoard[end] = transformedFigure
                self.board = newBoard
                self.activeColor = self.activeColor.oposite
                self.mateType = self.board.mate(for: boardFigure.color.oposite)
                completion(.success(self.mateType, positionToEat ?? end, additionalMove, transformedFigure))
                self.figureTransformationCompletion = nil
            }
            askForTransformation = true
        } else {
            board = newBoard
            activeColor = activeColor.oposite
            mateType = board.mate(for: boardFigure.color.oposite)
            completion(.success(mateType, positionToEat ?? end, additionalMove, nil))
        }
    }
}
