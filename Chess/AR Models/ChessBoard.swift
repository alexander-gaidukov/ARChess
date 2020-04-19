//
//  ChessBoard.swift
//  Chess
//
//  Created by Alexandr Gaidukov on 14.04.2020.
//  Copyright © 2020 Alexaner Gaidukov. All rights reserved.
//

import UIKit
import RealityKit
import Combine

enum GameResult {
    case draw
    case win(FigureColor)
}

protocol ChessBoardDelegate: class {
    func chessBoard(_ board: ChessBoard, didFinishGameWithResult result: GameResult)
}

final class ChessBoard: Entity, HasAnchoring, HasCollision {
    
    private weak var arView: ARView?
    private var realityKitScene: Experience.Figures
    
    private var tailEntities: [Tail] = []
    private var figureEntities: [Entity & HasCollision] = []
    private var coordinator: GameCoordinator
    
    private var boardGestureRecognizers: [EntityGestureRecognizer] = []
    private var figuresGestureRecognizers: [EntityGestureRecognizer] = []
    
    private let blackColor = #colorLiteral(red: 0.1176470588, green: 0.1176470588, blue: 0.1176470588, alpha: 1)
    private let whiteColor = #colorLiteral(red: 0.8823529412, green: 0.8823529412, blue: 0.8823529412, alpha: 1)
    
    private var startDragPosition: SIMD2<Int>?
    
    private let moveFocusEntity = FocusEntity(type: .focus)
    private let checkFocusEntity = FocusEntity(type: .error)
    
    var minimumBounds: SIMD2<Float>? = nil {
        didSet {
            guard let bounds = minimumBounds else { return }
            let minBounds = bounds.min()
            scale = SIMD3<Float>(repeating: minBounds / 8.0)
        }
    }
    
    weak var delegate: ChessBoardDelegate?
    
    private var animationHandler: Cancellable?
    
    private func tailColor(forRow row: Int, column: Int) -> UIColor {
        return row.isMultiple(of: 2) == column.isMultiple(of: 2) ? blackColor : whiteColor
    }
    
    private func flatPosition(forRow row: Int, column: Int) -> SIMD2<Float> {
        [-3.5 + Float(column), 3.5 - Float(row)]
    }
    
    private func tailPosition(forRow row: Int, column: Int) -> SIMD3<Float> {
        let position = flatPosition(forRow: row, column: column)
        return [position.x, 0.05, position.y]
    }
    
    private func figurePosition(forRow row: Int, column: Int) -> SIMD3<Float> {
        let position = flatPosition(forRow: row, column: column)
        return [position.x, 0.1, position.y]
    }
    
    private func focusPosition(forRow row: Int, column: Int) -> SIMD3<Float> {
        let position = flatPosition(forRow: row, column: column)
        return [position.x, 0.101, position.y]
    }
    
    private func coordinates(from position: SIMD3<Float>) -> SIMD2<Int>? {
        guard (-4..<4).contains(position.x) && (-4..<4).contains(position.z) else {
            return nil
        }
        
        let column = min(Int(floor(position.x + 4)), 7)
        let row = min(Int(floor(4 - position.z)), 7)
        
        return [row, column]
    }
    
    private func entity(for figure: Figure) -> (Entity & HasCollision) {
        
        let result: Entity
        
        switch (figure.type, figure.color) {
        case (.pawn, .white):
            result = realityKitScene.whitePawn!.clone(recursive: true)
        case (.rook, .white):
            result = realityKitScene.whiteRook!.clone(recursive: true)
        case (.knight, .white):
            result = realityKitScene.whiteKnight!.clone(recursive: true)
        case (.bishop, .white):
            result = realityKitScene.whiteBishop!.clone(recursive: true)
        case (.queen, .white):
            result = realityKitScene.whiteQueen!.clone(recursive: true)
        case (.king, .white):
            result = realityKitScene.whiteKing!.clone(recursive: true)
        case (.pawn, .black):
            result = realityKitScene.blackPawn!.clone(recursive: true)
        case (.rook, .black):
            result = realityKitScene.blackRook!.clone(recursive: true)
        case (.knight, .black):
            result = realityKitScene.blackKnight!.clone(recursive: true)
        case (.bishop, .black):
            result = realityKitScene.blackBishop!.clone(recursive: true)
        case (.queen, .black):
            result = realityKitScene.blackQueen!.clone(recursive: true)
        case (.king, .black):
            result = realityKitScene.blackKing!.clone(recursive: true)
        }
        
        let entity = result as! (Entity & HasCollision)
        
        entity.scale = SIMD3<Float>(repeating: 18)
        entity.generateCollisionShapes(recursive: false)
        entity.figure = figure
        
        if let arView = arView {
            let recognizer = arView.installGestures(.translation, for: entity).first!
            recognizer.removeTarget(nil, action: nil)
            recognizer.addTarget(self, action: #selector(handleTranslation(_:)))
            figuresGestureRecognizers.append(recognizer)
        }
        
        return entity
    }
    
    init(arView: ARView, realityKitScene: Experience.Figures, coordinator: GameCoordinator) {
        self.coordinator = coordinator
        self.arView = arView
        self.realityKitScene = realityKitScene
        super.init()
        
        for row in 0..<8 {
            for col in 0..<8 {
                let color = tailColor(forRow: row, column: col)
                let tail = Tail(color: color)
                tail.position = tailPosition(forRow: row, column: col)
                tailEntities.append(tail)
                addChild(tail)
            }
        }
        
        for row in 0..<8 {
            for col in 0..<8 {
                guard let figure = coordinator.board[[row, col]] else { continue }
                let figureEntity = entity(for: figure)
                figureEntity.position = figurePosition(forRow: row, column: col)
                self.figureEntities.append(figureEntity)
                addChild(figureEntity)
            }
        }
    }
    
    required init() {
        fatalError("init() has not been implemented")
    }
    
    func startScalingAndPositioning() {
        guard let arView = arView else { return }
        collision = CollisionComponent(shapes: [.generateBox(size: [8, 0.4, 8])])
        boardGestureRecognizers = arView.installGestures(.all, for: self)
        figuresGestureRecognizers.forEach { $0.isEnabled = false }
    }
    
    private func stopScalingAndPositioning() {
        collision = nil
        boardGestureRecognizers.forEach { $0.isEnabled = false }
    }
    
    func startGame() {
        stopScalingAndPositioning()
        figuresGestureRecognizers.forEach { $0.isEnabled = true }
    }
    
    private func showFocusEntity(_ focusEntity: FocusEntity, at position: SIMD2<Int>) {
        focusEntity.position = focusPosition(forRow: position[0], column: position[1])
        if focusEntity.parent == nil {
            addChild(focusEntity)
        }
    }
    
    @objc private func handleTranslation(_ recognizer: EntityTranslationGestureRecognizer) {
        if recognizer.state == .began {
            figuresGestureRecognizers.forEach {
                if $0 != recognizer { $0.isEnabled = false }
            }
            let location = recognizer.entity!.position
            guard let startPosition = coordinates(from: location) else { return }
            startDragPosition = startPosition
            showFocusEntity(moveFocusEntity, at: startPosition)
        } else if recognizer.state == .changed {
            guard let translation = recognizer.translation(in: self) else { return }
            let entity = recognizer.entity!
            entity.position += translation
            recognizer.setTranslation(.zero, in: self)
            if let coords = coordinates(from: entity.position) {
                showFocusEntity(moveFocusEntity, at: coords)
            } else {
                moveFocusEntity.removeFromParent()
            }
        } else if [.cancelled, .failed, .ended].contains(recognizer.state) {
            moveFocusEntity.removeFromParent()
            
            let entity = recognizer.entity!
            
            guard recognizer.state == .ended, let endPosition = coordinates(from: entity.position) else {
                moveFigure(entity, to: startDragPosition!)
                return
            }
            
            coordinator.move(figure: entity.figure!, from: startDragPosition!, to: endPosition) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case let .success(mateType, positionToEat, additionalMove, transformedFigure):
                    self.eatFigure(at: positionToEat, color: entity.figure!.color.oposite)
                    self.moveFigure(entity, to: endPosition, transformedFigure: transformedFigure)
                    if let am = additionalMove {
                        self.makeAdditionalMove(from: am.first!, to: am.last!)
                    }
                    self.handleMateState(mateType)
                case let .failure(position):
                    self.moveFigure(entity, to: self.startDragPosition!)
                    if let p = position {
                        self.showCheck(at: p, hideAfter: 0.5)
                    }
                }
                self.startDragPosition = nil
            }
            
        }
    }
    
    private func makeAdditionalMove(from start: SIMD2<Int>, to end: SIMD2<Int>) {
        for entity in figureEntities where entity.parent != nil {
            if let c = coordinates(from: entity.position), c == start {
                makeMove(entity: entity, position: end)
                break
            }
        }
    }
    
    private func showCheck(at position: SIMD2<Int>, hideAfter timeInterval: TimeInterval? = nil) {
        showFocusEntity(checkFocusEntity, at: position)
        if let time = timeInterval {
            DispatchQueue.main.asyncAfter(deadline: .now() + time) {
                self.checkFocusEntity.removeFromParent()
            }
        }
        
    }
    
    private func eatFigure(at position: SIMD2<Int>, color: FigureColor) {
        for entity in figureEntities where entity.parent != nil {
            if entity.figure!.color == color, let c = coordinates(from: entity.position), c == position {
                entity.removeFromParent()
                break
            }
        }
    }
    
    private func handleMateState(_ state: MateType) {
        switch state {
        case .not:
            checkFocusEntity.removeFromParent()
        case let .check(position):
            showCheck(at: position)
        case let .mate(color, position):
            showCheck(at: position)
            delegate?.chessBoard(self, didFinishGameWithResult: .win(color.oposite))
        case .stalemate, .draw:
            checkFocusEntity.removeFromParent()
            delegate?.chessBoard(self, didFinishGameWithResult: .draw)
        }
    }
    
    @discardableResult
    private func makeMove(entity: Entity, position: SIMD2<Int>) -> AnimationPlaybackController {
        var transform = entity.transform
        transform.translation = figurePosition(forRow: position[0], column: position[1])
        return entity.move(to: transform, relativeTo: self, duration: 0.25)
    }
    
    private func moveFigure(_ entity: Entity, to position: SIMD2<Int>, transformedFigure: Figure? = nil) {
        let myEvent = makeMove(entity: entity, position: position)
        animationHandler = scene?.subscribe(to: AnimationEvents.PlaybackCompleted.self, on: entity) {[weak self] event in
            guard event.playbackController == myEvent else { return }
            DispatchQueue.main.async {
                self?.animationHandler?.cancel()
                self?.animationHandler = nil
                if let tf = transformedFigure {
                    self?.transformFigure(entity, to: tf)
                }
                self?.figuresGestureRecognizers.forEach { $0.isEnabled = true }
            }
        }
    }
    
    private func transformFigure(_ figureEntity: Entity, to figure: Figure) {
        
        let newEntity = entity(for: figure)
        newEntity.position = figureEntity.position
        figureEntities.append(newEntity)
        figureEntity.removeFromParent()
        addChild(newEntity)
    }
    
}
