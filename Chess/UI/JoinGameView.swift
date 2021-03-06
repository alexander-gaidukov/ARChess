//
//  JoinGameView.swift
//  Chess
//
//  Created by Alexandr Gaidukov on 19.04.2020.
//  Copyright © 2020 Alexaner Gaidukov. All rights reserved.
//

import SwiftUI
import MultipeerConnectivity

struct LoadingIndicator: UIViewRepresentable {
    
    var isLoading: Bool
    
    func makeUIView(context: Context) -> UIActivityIndicatorView {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        if isLoading {
            indicator.startAnimating()
        }
        return indicator
    }
    
    func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) {
        if isLoading && !uiView.isAnimating {
            uiView.startAnimating()
        } else if !isLoading && uiView.isAnimating {
            uiView.stopAnimating()
        }
    }
}


struct AvailableGameView: View {
    var peerID: MCPeerID
    var isConnecting: Bool
    
    var body: some View {
        HStack {
            Text(peerID.displayName)
                .font(.headline)
            Spacer()
            LoadingIndicator(isLoading: isConnecting)
        }.padding()
    }
}

struct JoinGameView: View {
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject private var browser = GameBrowser()
    
    var body: some View {
        List {
            ForEach(Array(browser.peers.enumerated()), id: \.offset) { item in
                Button(action: {
                    self.browser.invite(peerId: item.element)
                }) {
                     AvailableGameView(peerID: item.element, isConnecting: item.element == self.browser.invitingPeer)
                }
            }
        }
        .onAppear { self.browser.start() }
        .onDisappear { self.browser.stop() }
        .onReceive(browser.$completed) { completed in
            if completed { self.presentationMode.wrappedValue.dismiss() }
        }
    }
}

#if DEBUG
struct JoinGameView_Previews: PreviewProvider {
    static var previews: some View {
        JoinGameView()
    }
}
#endif
