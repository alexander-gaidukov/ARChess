//
//  ContentView.swift
//  Chess
//
//  Created by Alexandr Gaidukov on 12.04.2020.
//  Copyright © 2020 Alexaner Gaidukov. All rights reserved.
//

import SwiftUI

struct PresentationState<Value> {
    var value: Value? = nil
    var presented: Bool {
        get {
            value != nil
        }
        set {
            if !newValue { value = nil }
        }
    }
}

struct MainButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(lineWidth: 2.0)
            .foregroundColor(configuration.isPressed ? Color.clear : Color.blue)
            .background(configuration.isPressed ? Color.blue : Color.white.opacity(0.001))
            .cornerRadius(8)
            .overlay(configuration.label)
    }
}

struct ContentView : View {
    
    enum SheetType {
        case host
        case join
    }
    
    @State var gameStarted: Bool = false
    @State var sheetState: PresentationState<SheetType> = PresentationState()
    
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
                HStack(spacing: 20) {
                    Button(action: {
                        self.sheetState.value = .host
                    }){ Text("Host Game") }
                        .frame(height: 60)
                        .buttonStyle(MainButtonStyle())
                    Button(action: {
                        self.sheetState.value = .join
                    }){ Text("Join Game") }
                        .frame(height: 60)
                        .buttonStyle(MainButtonStyle())
                }.padding()
            }.overlay(NavigationLink(destination: GameView(presented: $gameStarted), isActive: $gameStarted) { EmptyView() })
            .navigationBarTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $sheetState.presented, onDismiss: { self.checkSession() }) {
                if self.sheetState.value == .host {
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
