//
//  GameBoard.swift
//  Chess
//
//  Created by Alexandr Gaidukov on 12.04.2020.
//  Copyright © 2020 Alexaner Gaidukov. All rights reserved.
//

import UIKit

func <(lhs: FigureType, rhs: FigureType) -> Bool {
    return lhs.rawValue < rhs.rawValue
}

func ==(lhs: Figure, rhs: Figure) -> Bool {
    return lhs.color == rhs.color && lhs.type == rhs.type
}

func <(lhs: Figure, rhs: Figure) -> Bool {
    return lhs.type < rhs.type
}

enum FigureType: Int, Equatable, Comparable, Codable {
    case pawn
    case knight
    case bishop
    case rook
    case queen
    case king
}

enum FigureColor: Int, Equatable, Codable {
    case white
    case black
    
    var oposite: FigureColor {
        switch self {
        case .white:
            return .black
        case .black:
            return .white
        }
    }
}

enum MateType {
    case not
    case check(SIMD2<Int>)
    case mate(FigureColor, SIMD2<Int>)
    case stalemate
    case draw
}

enum KingChangeSide: Equatable {
    case left
    case right
}

struct Figure: Comparable {
    let type: FigureType
    let color: FigureColor
}

extension Figure {
    var image: UIImage {
        switch (type, color) {
        case (.pawn, .white):
            return #imageLiteral(resourceName: "WhitePawn")
        case (.rook, .white):
            return #imageLiteral(resourceName: "WhiteRook")
        case (.knight, .white):
            return #imageLiteral(resourceName: "WhiteKnight")
        case (.bishop, .white):
            return #imageLiteral(resourceName: "WhiteBishop")
        case (.queen, .white):
            return #imageLiteral(resourceName: "WhiteQueen")
        case (.king, .white):
            return #imageLiteral(resourceName: "WhiteKing")
        case (.pawn, .black):
            return #imageLiteral(resourceName: "BlackPawn")
        case (.rook, .black):
            return #imageLiteral(resourceName: "BlackRook")
        case (.knight, .black):
            return #imageLiteral(resourceName: "BlackKnight")
        case (.bishop, .black):
            return #imageLiteral(resourceName: "BlackBishop")
        case (.queen, .black):
            return #imageLiteral(resourceName: "BlackQueen")
        case (.king, .black):
            return #imageLiteral(resourceName: "BlackKing")
        }
    }
}

typealias Board = [[Figure?]]

struct GameBoard {
    private var board: Board = []
    
    let size = 8
    
    var colorMoves: FigureColor = .white
    
    var bittenField: SIMD2<Int>? = nil
    
    var kingChangeSides: [FigureColor: Set<KingChangeSide>] = [
        .white: [.left, .right],
        .black: [.left, .right]
    ]
    
    
    init() {
        var board: Board = Array(repeating: Array(repeating: nil, count: size), count: size)
        for i in 0..<size {
            board[1][i] = Figure(type: .pawn, color: .white)
            board[size - 2][i] = Figure(type: .pawn, color: .black)
        }
        
        for (i, element) in [FigureType.rook, FigureType.knight, FigureType.bishop].enumerated() {
            board[0][i] = Figure(type: element, color: .white)
            board[0][size - 1 - i] = Figure(type: element, color: .white)
            
            board[size - 1][i] = Figure(type: element, color: .black)
            board[size - 1][size - 1 - i] = Figure(type: element, color: .black)
        }
        
        board[0][3] = Figure(type: .queen, color: .white)
        board[0][4] = Figure(type: .king, color: .white)
        
        board[size - 1][3] = Figure(type: .queen, color: .black)
        board[size - 1][4] = Figure(type: .king, color: .black)
        self.board = board
    }
    
    subscript (_ index: SIMD2<Int>) -> Figure? {
        get {
            return board[index[0]][index[1]]
        }
        mutating set {
            board[index[0]][index[1]] = newValue
        }
    }
    
    mutating func makeMove(from start: SIMD2<Int>, to end: SIMD2<Int>) {
        
        guard let figure = self[start] else { fatalError() }
        if figure.type == .pawn, abs(start[0] - end[0]) == 2 {
            bittenField = [min(start[0], end[0]) + 1, start[1]]
        } else {
            bittenField = nil
        }
        
        if figure.type == .king {
            kingChangeSides[figure.color] = []
        }
        
        if figure.type == .rook, start[1] == 0 {
            var sides = kingChangeSides[figure.color]!
            sides.remove(.left)
            kingChangeSides[figure.color] = sides
        }
        
        if figure.type == .rook, start[1] == size - 1 {
            var sides = kingChangeSides[figure.color]!
            sides.remove(.right)
            kingChangeSides[figure.color] = sides
        }
        
        self[end] = self[start]
        self[start] = nil
        
        if figure.type == .king && abs(end[1] - start[1]) == 2 {
            let rookPosition: SIMD2<Int> = [start[0], end[1] > start[1] ? size - 1 : 0]
            let rook = self[rookPosition]!
            self[rookPosition] = nil
            self[[end[0], end[1] > start[1] ? end[1] - 1 : end[1] + 1]] = rook
        }
    }
    
    func makingMove(from start: SIMD2<Int>, to end: SIMD2<Int>) -> GameBoard {
        var result = self
        result.makeMove(from: start, to: end)
        return result
    }
    
    func isAvailableMove(from start: SIMD2<Int>, to end: SIMD2<Int>) -> Bool {
        guard let figure = self[start] else { return false }
        return figureAvailableMoves(figure, position: start, kingChange: true).contains(end)
    }
    
    // MARK: - Available moves
    
    private func pawnAvailableMoves(from position: SIMD2<Int>, color: FigureColor) -> Set<SIMD2<Int>> {
        var result: Set<SIMD2<Int>> = []
        let firstMove = (color == .white && position[0] == 1) || (color == .black && position[0] == size - 2)
        let offset = color == .white ? 1 : -1
        let nextRow = position[0] + offset
        let column = position[1]
        guard nextRow < size && nextRow >= 0 else { return result }
        
        if board[nextRow][column] == nil {
            result.insert([nextRow, column])
            if firstMove {
                let secondRow = nextRow + offset
                if board[secondRow][column] == nil {
                    result.insert([secondRow, column])
                }
            }
        }
        
        let leftColumn = column - 1
        if leftColumn >= 0, let figure = board[nextRow][leftColumn], figure.color == color.oposite {
            result.insert([nextRow, leftColumn])
        }
        
        if let field = bittenField, field == [nextRow, leftColumn] {
            result.insert(field)
        }
        
        let rightColumn = column + 1
        if rightColumn < size, let figure = board[nextRow][rightColumn], figure.color == color.oposite {
            result.insert([nextRow, rightColumn])
        }
        
        if let field = bittenField, field == [nextRow, rightColumn] {
            result.insert(field)
        }
        
        return result
    }
    
    private func rookAvailableMoves(from position: SIMD2<Int>, color: FigureColor) -> Set<SIMD2<Int>> {
        var result: Set<SIMD2<Int>> = []
        // up
        var nextRow = position[0] + 1
        let column = position[1]
        while nextRow < size {
            if let figure = board[nextRow][column] {
                if figure.color == color.oposite {
                    result.insert([nextRow, column])
                }
                break
            } else {
                result.insert([nextRow, column])
            }
            nextRow += 1
        }
        
        // down
        nextRow = position[0] - 1
        while nextRow >= 0 {
            if let figure = board[nextRow][column] {
                if figure.color == color.oposite {
                    result.insert([nextRow, column])
                }
                break
            } else {
                result.insert([nextRow, column])
            }
            nextRow -= 1
        }
        
        // right
        let row = position[0]
        var nextColumn = position[1] + 1
        while nextColumn < size {
            if let figure = board[row][nextColumn] {
                if figure.color == color.oposite {
                    result.insert([row, nextColumn])
                }
                break
            } else {
                result.insert([row, nextColumn])
            }
            nextColumn += 1
        }
        
        // left
        nextColumn = position[1] - 1
        while nextColumn >= 0 {
            if let figure = board[row][nextColumn] {
                if figure.color == color.oposite {
                    result.insert([row, nextColumn])
                }
                break
            } else {
                result.insert([row, nextColumn])
            }
            nextColumn -= 1
        }
        
        return result
    }
    
    private func knightAvailableMoves(from position: SIMD2<Int>, color: FigureColor) -> Set<SIMD2<Int>> {
        var result: Set<SIMD2<Int>> = []
        
        let alailablePositions: [SIMD2<Int>] = [
            [position[0] - 2, position[1] - 1],
            [position[0] - 2, position[1] + 1],
            [position[0] + 2, position[1] - 1],
            [position[0] + 2, position[1] + 1],
            [position[0] - 1, position[1] - 2],
            [position[0] - 1, position[1] + 2],
            [position[0] + 1, position[1] - 2],
            [position[0] + 1, position[1] + 2]
        ]
        
        for pos in alailablePositions {
            if (0..<size).contains(pos[0]) && (0..<size).contains(pos[1]) {
                let figure = self[pos]
                if figure == nil || figure!.color == color.oposite {
                    result.insert(pos)
                }
            }
        }
        
        return result
    }
    
    private func bishopAvailableMoves(from position: SIMD2<Int>, color: FigureColor) -> Set<SIMD2<Int>> {
        
        var result: Set<SIMD2<Int>> = []
        
        // top-left
        var nextRow = position[0] + 1
        var nextCol = position[1] - 1
        while nextRow < size && nextCol >= 0 {
            if let figure = board[nextRow][nextCol] {
                if figure.color == color.oposite {
                    result.insert([nextRow, nextCol])
                }
                break
            } else {
                result.insert([nextRow, nextCol])
            }
            nextRow += 1
            nextCol -= 1
        }
        
        // top-right
        nextRow = position[0] + 1
        nextCol = position[1] + 1
        while nextRow < size && nextCol < size {
            if let figure = board[nextRow][nextCol] {
                if figure.color == color.oposite {
                    result.insert([nextRow, nextCol])
                }
                break
            } else {
                result.insert([nextRow, nextCol])
            }
            nextRow += 1
            nextCol += 1
        }
        
        // bottom-right
        nextRow = position[0] - 1
        nextCol = position[1] + 1
        while nextRow >= 0 && nextCol < size {
            if let figure = board[nextRow][nextCol] {
                if figure.color == color.oposite {
                    result.insert([nextRow, nextCol])
                }
                break
            } else {
                result.insert([nextRow, nextCol])
            }
            nextRow -= 1
            nextCol += 1
        }
        
        // bottom-left
        nextRow = position[0] - 1
        nextCol = position[1] - 1
        while nextRow >= 0 && nextCol >= 0 {
            if let figure = board[nextRow][nextCol] {
                if figure.color == color.oposite {
                    result.insert([nextRow, nextCol])
                }
                break
            } else {
                result.insert([nextRow, nextCol])
            }
            nextRow -= 1
            nextCol -= 1
        }
        
        return result
    }
    
    private func queenAvailableMoves(from position: SIMD2<Int>, color: FigureColor) -> Set<SIMD2<Int>> {
        // Queen moves is a combination of rook and bishop moves
        let rookMoves = rookAvailableMoves(from: position, color: color)
        let bishopMoves = bishopAvailableMoves(from: position, color: color)
        return rookMoves.union(bishopMoves)
    }
    
    private func kingAvailableMoves(from position: SIMD2<Int>, color: FigureColor, kingChange: Bool) -> Set<SIMD2<Int>> {
        var result: Set<SIMD2<Int>> = []
        for r in -1...1 {
            for c in -1...1 {
                let row = position[0] + r
                let col = position[1] + c
                if (0..<size).contains(row) && (0..<size).contains(col) {
                    let figure = board[row][col]
                    if figure == nil || figure!.color == color.oposite {
                        result.insert([row, col])
                    }
                }
            }
        }
        
        guard kingChange else { return result }
        
        if kingChangeSides[color]!.contains(.left) {
            var can: Bool = true
            for i in 1..<position[1] {
                if board[position[0]][i] != nil {
                    can = false
                    break
                }
            }
            if can {
                var hasCheck = false
                for i in 0..<3 {
                    if check(color: color, kingPosition: [position[0], position[1] - i]) != nil {
                        hasCheck = true
                        break
                    }
                }
                if !hasCheck {
                    result.insert([position[0], position[1] - 2])
                }
            }
        }
        
        if kingChangeSides[color]!.contains(.right) {
            var can: Bool = true
            for i in (position[1] + 1)..<(size - 1){
                if board[position[0]][i] != nil {
                    can = false
                    break
                }
            }
            if can {
                var hasCheck = false
                for i in 0..<3 {
                    if check(color: color, kingPosition: [position[0], position[1] + i]) != nil {
                        hasCheck = true
                        break
                    }
                }
                if !hasCheck {
                    result.insert([position[0], position[1] + 2])
                }
                
            }
        }
        
        return result
    }
    
    private func figureAvailableMoves(_ figure: Figure, position: SIMD2<Int>, kingChange: Bool) -> Set<SIMD2<Int>> {
        switch figure.type {
        case .pawn:
            return pawnAvailableMoves(from: position, color: figure.color)
        case .rook:
            return rookAvailableMoves(from: position, color: figure.color)
        case .knight:
            return knightAvailableMoves(from: position, color: figure.color)
        case .bishop:
            return bishopAvailableMoves(from: position, color: figure.color)
        case .queen:
            return queenAvailableMoves(from: position, color: figure.color)
        case .king:
            return kingAvailableMoves(from: position, color: figure.color, kingChange: kingChange)
        }
    }
    
    // MARK: - Check, Mate, Stalemate
    
    func kingPosition(color: FigureColor) -> SIMD2<Int> {
        for (rowIdx, row) in board.enumerated() {
            for (colIdx, figure) in row.enumerated() {
                if let f = figure, f.type == .king, f.color == color {
                    return [rowIdx, colIdx]
                }
            }
        }
        fatalError()
    }
    
    private func check(color: FigureColor, kingPosition: SIMD2<Int>) -> SIMD2<Int>? {
        for (rowIdx, row) in board.enumerated() {
            for (colIdx, figure) in row.enumerated() {
                if let f = figure, f.color == color.oposite, figureAvailableMoves(f, position: [rowIdx, colIdx], kingChange: false).contains(kingPosition) {
                    return [rowIdx, colIdx]
                }
            }
        }
        
        return nil
    }
    
    private func hasEnoughFiguresToContinue() -> Bool {
        var whiteFigues: [Figure] = []
        var blackFigures: [Figure] = []
        for row in board {
            for figure in row {
                if let f = figure, f.type != .king {
                    if f.color == .white {
                        whiteFigues.append(f)
                    } else {
                        blackFigures.append(f)
                    }
                }
            }
        }
        
        let whiteHasEnoughFigures = whiteFigues.count > 1 || [.queen, .rook, .pawn].contains(whiteFigues.first?.type)
        let blackHasEnoughFigures = blackFigures.count > 1 || [.queen, .rook, .pawn].contains(blackFigures.first?.type)
        
        return whiteHasEnoughFigures || blackHasEnoughFigures
    }
    
    func check(color: FigureColor) -> SIMD2<Int>? {
        check(color: color, kingPosition: kingPosition(color: color))
    }
    
    func mate(for color: FigureColor) -> MateType {
        
        guard hasEnoughFiguresToContinue() else{
            return .draw
        }
        
        var figures: [(element: Figure, position: SIMD2<Int>)] = []
        for (rowIdx, row) in board.enumerated() {
            for (colIdx, figure) in row.enumerated() {
                if let f = figure, f.color == color {
                    figures.append((f, [rowIdx, colIdx]))
                }
            }
        }
        
        let kPosition = kingPosition(color: color)
        
        let hasCheck = check(color: color) != nil
        let availableMoves = figures.compactMap { (element: Figure, position: SIMD2<Int>) -> (position: SIMD2<Int>, moves: Set<SIMD2<Int>>)? in
            let moves = figureAvailableMoves(element, position: position, kingChange: true)
            guard !moves.isEmpty else { return nil }
            return (position, moves)
        }
        
        guard !availableMoves.isEmpty else {
            return hasCheck ? .mate(color, kPosition) : .stalemate
        }
        
        for move in availableMoves {
            for position in move.moves {
                let newBoard = makingMove(from: move.position, to: position)
                if newBoard.check(color: color) == nil {
                    return hasCheck ? .check(kPosition) : .not
                }
            }
        }
        
        return hasCheck ? .mate(color, kPosition) : .stalemate
    }
}
