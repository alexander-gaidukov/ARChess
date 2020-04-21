//
//  ContentView.swift
//  Chess
//
//  Created by Alexandr Gaidukov on 12.04.2020.
//  Copyright © 2020 Alexaner Gaidukov. All rights reserved.
//

import SwiftUI

struct ContentView : View {
    
    struct SheetState {
        enum SheetType {
            case host
            case join
        }
        var sheetType: SheetType? = nil
        var presented: Bool {
            get {
                sheetType != nil
            }
            set {
                if !newValue { sheetType = nil }
            }
        }
    }
    
    @State var gameStarted: Bool = false
    @State var sheetState: SheetState = SheetState()
    
    func checkSession() {
        guard !gameStarted, !GameSession.shared.mcSession.connectedPeers.isEmpty else { return }
        gameStarted = true
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .center) {
                Text("Chess Game")
                    .font(.title)
                Spacer()
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                Spacer()
                HStack {
                    Button(action: {
                        self.sheetState.sheetType = .host
                    }){ Text("Host Game") }
                        .buttonStyle(MainButtonStyle())
                        .frame(width: 150)
                    Button(action: {
                        self.sheetState.sheetType = .join
                    }){ Text("Join Game") }
                        .buttonStyle(MainButtonStyle())
                        .frame(width: 150)
                    }
            }.overlay(NavigationLink(destination: GameView(presented: $gameStarted), isActive: $gameStarted) { EmptyView() })
            .navigationBarTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $sheetState.presented, onDismiss: { self.checkSession() }) {
                if self.sheetState.sheetType == .host {
                    HostGameView()
                } else {
                    JoinGameView()
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
