//
//  ChessARView.swift
//  Chess
//
//  Created by Alexandr Gaidukov on 14.04.2020.
//  Copyright © 2020 Alexaner Gaidukov. All rights reserved.
//

import RealityKit
import UIKit
import ARKit
import Combine
import MultipeerConnectivity

extension float4x4 {
    func normalized() -> float4x4 {
        var result = self
        result.columns.0 = simd.normalize(result.columns.0)
        result.columns.1 = simd.normalize(result.columns.1)
        result.columns.2 = simd.normalize(result.columns.2)
        return result
    }
}

final class ChessARView: ARView {
    
    private let minimumBoardBounds: SIMD2<Float> = [0.5, 0.5]
    
    private var figures: Experience.Figures? {
        didSet {
            if gameCoordinator.state == .waitingForGameElements {
                gameCoordinator.state = .positioning
            }
        }
    }
    
    private var gameAnchor: ARAnchor?
    private var anchoringObserver: Cancellable?
    private var stateObserver: Cancellable?
    
    private let coachingOverlayView = ARCoachingOverlayView()
    private var gameBoard: ChessBoard?
    
    private var gameCoordinator: GameCoordinator
    
    private lazy var configuration: ARWorldTrackingConfiguration = {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.frameSemantics = .personSegmentationWithDepth
        configuration.isCollaborationEnabled = true
        return configuration
    }()
    
    init(frame frameRect: CGRect, coordinator: GameCoordinator) {
        gameCoordinator = coordinator
        super.init(frame: frameRect)
        
        stateObserver = gameCoordinator.$state.sink { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .initCoaching:
                break
            case .planeSearching:
                break
            case .waitingForTheHostGame:
                break
            case .waitingForGameElements:
                break
            case .positioning:
                self.positionContent()
            case .scaling:
                self.startScaling()
            case .playing:
                if self.gameCoordinator.gameSession.isHost {
                    self.gameCoordinator.sendMessage(.gameBegins)
                }
                self.startGame()
            case .waitingForTheOtherPlayer:
                break
            }
        }
        coordinator.gameSession.mcSession.delegate = self
        configureSession()
        startCoaching()
        configureGestures()
        Experience.loadFiguresAsync { result in
            DispatchQueue.main.async {
                self.figures = try! result.get()
            }
        }
    }
    
    @objc required dynamic init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc required dynamic init(frame frameRect: CGRect) {
        fatalError("init(frame:) has not been implemented")
    }
    
    private func configureSession() {
        session.delegate = self
        session.run(configuration)
    }
    
    private func configureGestures() {
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTouch(_:))))
    }
    
    private func startCoaching() {
        coachingOverlayView.goal = .horizontalPlane
        coachingOverlayView.session = session
        coachingOverlayView.delegate = self
        coachingOverlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(coachingOverlayView)
        coachingOverlayView.setActive(true, animated: true)
        
        if !gameCoordinator.gameSession.isHost {
            coachingOverlayView.activatesAutomatically = false
        }
    }
    
    private func resetSession() {
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    private func positionContent() {
        guard gameBoard == nil, let anchor = gameAnchor else { return }
        guard let figures = figures else {
            gameCoordinator.state = .waitingForGameElements
            return
        }
        let board = ChessBoard(arView: self, realityKitScene: figures, coordinator: gameCoordinator)
        board.minimumBounds = [0.5, 0.5]
        board.anchoring = AnchoringComponent(anchor)
        board.delegate = self
        anchoringObserver = scene.subscribe(to: SceneEvents.AnchoredStateChanged.self, on: board) {[weak self] event in
            guard event.isAnchored else { return }
            DispatchQueue.main.async {
                self?.anchoringObserver?.cancel()
                self?.anchoringObserver = nil
                self?.gameCoordinator.state = .scaling
            }
        }
        scene.anchors.append(board)
        self.gameBoard = board
    }
    
    private func startScaling() {
        guard let gameBoard = self.gameBoard else { return }
        gameBoard.startScalingAndPositioning()
    }
    
    private func startGame() {
        guard let gameBoard = self.gameBoard else { return }
        gameBoard.startGame()
    }
    
    @objc private func handleTouch(_ recognizer: UITapGestureRecognizer) {
        if gameCoordinator.state == .planeSearching {
            guard let result = raycast(from: recognizer.location(in: self), allowing: .existingPlaneGeometry, alignment: .horizontal).first,
                let anchor = result.anchor as? ARPlaneAnchor,
                anchor.alignment == .horizontal,
                anchor.extent.x >= minimumBoardBounds.x,
                anchor.extent.z >= minimumBoardBounds.y else { return }
            let arAnchor = ARAnchor(name: "Game Anchor", transform: anchor.transform.normalized())
            session.add(anchor: arAnchor)
        }
    }
}

extension ChessARView: ARSessionDelegate {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        if let gameAnchor = anchors.first(where: { $0.name == "Game Anchor" }) {
            self.gameAnchor = gameAnchor
            gameCoordinator.state = .positioning
        } else if !gameCoordinator.gameSession.isHost, anchors.firstIndex(where: { $0 is ARParticipantAnchor }) != nil {
            coachingOverlayView.setActive(false, animated: true)
        }
    }
    
    func session(_ session: ARSession, didOutputCollaborationData data: ARSession.CollaborationData) {
        guard let encodedData = try? NSKeyedArchiver.archivedData(withRootObject: data, requiringSecureCoding: true) else { return }
        try? gameCoordinator.gameSession.mcSession.send(encodedData, toPeers: gameCoordinator.gameSession.mcSession.connectedPeers, with: data.priority == .critical ? .reliable : .unreliable)
    }
}

extension ChessARView: ARCoachingOverlayViewDelegate {
    func coachingOverlayViewDidRequestSessionReset(_ coachingOverlayView: ARCoachingOverlayView) {
        resetSession()
    }
    
    func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        coachingOverlayView.activatesAutomatically = false
        gameCoordinator.state = gameCoordinator.gameSession.isHost ? .planeSearching : .waitingForTheHostGame
    }
}

extension ChessARView: ChessBoardDelegate {
    func chessBoard(_ board: ChessBoard, didFinishGameWithResult result: GameResult) {
        let message: String
        switch result {
        case .draw:
            message = "Draw"
        case .win(let color):
            message = color == .white ? "White won!" : "Black won!"
        }
        
        let entity = ModelEntity(mesh: .generateText(message, font: .systemFont(ofSize: 1), containerFrame: CGRect(origin: .zero, size: CGSize(width: 8, height: 1)), alignment: .center), materials: [SimpleMaterial(color: #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1), isMetallic: true)])
        entity.position = [-4, -0.5, 0]
        board.addChild(entity)
    }
}

extension ChessARView: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        if state == .notConnected {
            DispatchQueue.main.async {
                self.gameCoordinator.oponentLeaveTheGame()
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let collaborationData = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARSession.CollaborationData.self, from: data) {
            self.session.update(with: collaborationData)
            return
        }
        
        guard let message = try? JSONDecoder().decode(Message.self, from: data) else { return }
        switch message {
        case .iAMReady:
            if gameCoordinator.gameSession.isHost { gameCoordinator.isSecondPlayerReady = true }
        case .gameBegins:
            if !gameCoordinator.gameSession.isHost { gameCoordinator.state = .playing }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
}
