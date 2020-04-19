//
//  GameAdvertiser.swift
//  Chess
//
//  Created by Alexandr Gaidukov on 19.04.2020.
//  Copyright © 2020 Alexaner Gaidukov. All rights reserved.
//

import MultipeerConnectivity
import Combine
import SwiftUI

final class GameAdvertiser: NSObject, ObservableObject {
    
    var gameSession: GameSession
    @Published var candidatePeerID: MCPeerID?
    @Published var sessionState: MCSessionState = .notConnected
    
    @Binding var completed: Bool
    
    private var invitationCompletion: ((Bool, MCSession?) -> ())?
    
    private let peerID = MCPeerID(displayName: UIDevice.current.name)
    private lazy var advertiser: MCNearbyServiceAdvertiser = {
        MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: MultipeerGame.serviceType)
    }()
    
    
    var shouldShowConfirmation: Bool {
        get {
            candidatePeerID != nil
        }
        set {
            if !newValue { candidatePeerID = nil }
        }
    }
    
    var sessionMessage: String {
        switch sessionState {
        case .notConnected:
            return "Waiting for the other player"
        case .connecting:
            return "Connecting"
        case .connected:
            return "Connected"
        @unknown default:
            return ""
        }
    }
    
    init(completed: Binding<Bool>, gameSession: GameSession) {
        self.gameSession = gameSession
        self._completed = completed
        super.init()
    }
    
    func start() {
        gameSession.mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        gameSession.mcSession?.delegate = self
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
    }
    
    func stop() {
        gameSession.mcSession?.delegate = nil
        advertiser.delegate = nil
        advertiser.stopAdvertisingPeer()
    }
    
    func acceptInvitation() {
        guard let session = gameSession.mcSession else { return }
        invitationCompletion?(true, session)
        invitationCompletion = nil
    }
    
    func declineInvitation() {
        invitationCompletion?(false, nil)
        invitationCompletion = nil
    }
}

extension GameAdvertiser: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationCompletion = invitationHandler
        candidatePeerID = peerID
    }
}

extension GameAdvertiser: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        sessionState = state
        if state == .connected {
            completed = true
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // Nothing
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // Nothing
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // Nothing
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // Nothing
    }
    
    
}
