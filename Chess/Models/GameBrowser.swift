//
//  GameBrowser.swift
//  Chess
//
//  Created by Alexandr Gaidukov on 19.04.2020.
//  Copyright © 2020 Alexaner Gaidukov. All rights reserved.
//

import MultipeerConnectivity
import Combine
import SwiftUI

struct MultipeerGame {
    static var serviceType = "chessgame"
}

final class GameBrowser: NSObject, ObservableObject {
    
    private let inviteTimeout: TimeInterval = 30
    
    private var gameSession: GameSession {
        GameSession.shared
    }
    
    @Published var peers: [MCPeerID] = []
    @Published var invitingPeer: MCPeerID? = nil
    
    @Binding var completed: Bool
    
    private let peerID = MCPeerID(displayName: UIDevice.current.name)
    private lazy var browser: MCNearbyServiceBrowser = {
        MCNearbyServiceBrowser(peer: peerID, serviceType: MultipeerGame.serviceType)
    }()
    
    init(completed: Binding<Bool>) {
        self._completed = completed
        super.init()
    }
    
    func start() {
        gameSession.isHost = false
        gameSession.mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        gameSession.mcSession?.delegate = self
        browser.delegate = self
        browser.startBrowsingForPeers()
    }
    
    func stop() {
        gameSession.mcSession?.delegate = nil
        browser.delegate = nil
        browser.stopBrowsingForPeers()
    }
    
    func invite(peerId: MCPeerID) {
        guard let session = gameSession.mcSession else { return }
        browser.invitePeer(peerId, to: session, withContext: nil, timeout: inviteTimeout)
        invitingPeer = peerId
        DispatchQueue.main.asyncAfter(deadline: .now() + inviteTimeout) {[weak self] in
            self?.invitingPeer = nil
        }
    }
}

extension GameBrowser: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        guard !peers.contains(peerID) else { return }
        peers.append(peerID)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        guard let index = peers.firstIndex(of: peerID) else { return }
        peers.remove(at: index)
    }
}

extension GameBrowser: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .notConnected:
                self.invitingPeer = nil
            case .connecting:
                break
            case .connected:
                self.invitingPeer = nil
                self.completed = true
            @unknown default:
                break
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
}
