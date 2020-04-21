//
//  GameView.swift
//  Chess
//
//  Created by Alexandr Gaidukov on 17.04.2020.
//  Copyright © 2020 Alexaner Gaidukov. All rights reserved.
//

import SwiftUI
import RealityKit

struct KilledFiguresStack: View {
    let figures: [Figure]
    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(Array(figures.enumerated()), id: \.offset) { item in
                Image(uiImage: item.element.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 8)
            }
        }
    }
}

struct GameView : View {
    
    @ObservedObject var gameCoordinator: GameCoordinator
    
    init(presented: Binding<Bool>, gameSession: GameSession) {
        gameCoordinator = GameCoordinator(gameSession: gameSession, quit: presented.negate)
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            ARViewContainer(coordinator: gameCoordinator)
                .edgesIgnoringSafeArea(.all)
                .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
                .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
            VStack {
                if gameCoordinator.infoMessage != nil {
                    Text(gameCoordinator.infoMessage!)
                        .padding(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                        .background(Color.gray)
                        .cornerRadius(4)
                        .padding(EdgeInsets(top: 0, leading: 44, bottom: 8, trailing: 44))
                }
                HStack {
                    KilledFiguresStack(figures: self.gameCoordinator.whiteKilledFigures)
                    Spacer()
                    KilledFiguresStack(figures: self.gameCoordinator.blackKilledFigures)
                }
                .padding(.horizontal)
                Spacer()
                if self.gameCoordinator.startButtonVisible {
                    Button(action: {
                        DispatchQueue.main.async {
                            self.gameCoordinator.startGame()
                        }
                    }) {
                        Text("Start")
                    }
                    .buttonStyle(MainButtonStyle())
                }
            }
            Button(action: {self.gameCoordinator.askToQuitTheGame() }) {
                Text("X")
                    .font(.title)
                    .foregroundColor(Color.gray)
                    .frame(width: 44, height: 44)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .actionSheet(isPresented: $gameCoordinator.askForTransformation) {
            ActionSheet(title: Text("Choose figure type"), message: nil, buttons: [
                .default(Text("Queen")) {
                    DispatchQueue.main.async {
                        self.gameCoordinator.figureTransformationCompletion?(.queen)
                    }
                },
                .default(Text("Rook")) {
                    DispatchQueue.main.async {
                        self.gameCoordinator.figureTransformationCompletion?(.rook)
                    }
                },
                .default(Text("Bishop")) {
                    DispatchQueue.main.async {
                        self.gameCoordinator.figureTransformationCompletion?(.bishop)
                    }
                },
                .default(Text("Knight")) {
                    DispatchQueue.main.async {
                        self.gameCoordinator.figureTransformationCompletion?(.knight)
                    }
                }
            ])
        }
        .alert(isPresented: $gameCoordinator.shouldShowAlert) {
            if gameCoordinator.oponentDidLeaveTheGame {
                return Alert(title: Text("You oponent left the game"),
                             message: nil,
                             dismissButton: .default(Text("OK")){
                                self.gameCoordinator.quitTheGame()
                            })
            }
            
            return Alert(title: Text("Do you really want to quit the game?"),
                        message: nil,
                        primaryButton: .destructive(Text("Quit")){
                            self.gameCoordinator.quitTheGame()
                        },
                        secondaryButton: .cancel())
        }
    }
}

struct MainButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(configuration.isPressed ? .white: .blue)
            .frame(height: 60)
            .frame(maxWidth: .infinity)
            .background(configuration.isPressed ? Color.blue : Color.white.opacity(0.001))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8).stroke(configuration.isPressed ? Color.clear : Color.blue, style: StrokeStyle(lineWidth: 2))
            )
            .padding(.horizontal)
    }
}

struct ARViewContainer: UIViewRepresentable {
    
    var coordinator: GameCoordinator
    
    func makeUIView(context: Context) -> ChessARView {
        FigureComponent.registerComponent()
        let arView = ChessARView(frame: .zero, coordinator: coordinator)
        return arView
    }
    
    func updateUIView(_ uiView: ChessARView, context: Context) {}
    
}

#if DEBUG
struct GameView_Previews : PreviewProvider {
    @State static var presented: Bool = true
    static var previews: some View {
        GameView(presented: $presented, gameSession: GameSession())
    }
}
#endif
