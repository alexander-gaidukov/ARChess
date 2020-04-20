//
//  ContentView.swift
//  Chess
//
//  Created by Alexandr Gaidukov on 12.04.2020.
//  Copyright © 2020 Alexaner Gaidukov. All rights reserved.
//

import SwiftUI



struct ContentView : View {
    
    enum SheetType {
        case host
        case join
    }
    
    @State var gameSession = GameSession()
    
    @State var gameStarted: Bool = false
    @State var sheetPresented: Bool = false
    @State var sheetType: SheetType = .host
    
    func checkSession() {
        guard !gameStarted, let session = gameSession.mcSession, !session.connectedPeers.isEmpty else { return }
        gameStarted = true
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .center) {
                NavigationLink(destination: GameView(presented: $gameStarted), isActive: $gameStarted) { Text("") }.hidden()
                Text("Chess Game")
                    .font(.title)
                Spacer()
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                Spacer()
                HStack {
                    Button(action: {
                        self.sheetType = .host
                        self.sheetPresented = true
                    }){ Text("Host Game") }
                        .buttonStyle(MainButtonStyle())
                        .frame(width: 150)
                    Button(action: {
                        self.sheetType = .join
                        self.sheetPresented = true
                    }){ Text("Join Game") }
                        .buttonStyle(MainButtonStyle())
                        .frame(width: 150)
                }
            }
            .navigationBarTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $sheetPresented, onDismiss: { self.checkSession() }) {
                if self.sheetType == .host {
                    HostGameView(gameSession: self.gameSession, presented: self.$sheetPresented)
                } else {
                    JoinGameView(gameSession: self.gameSession, presented: self.$sheetPresented)
                }
            }
        }
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
