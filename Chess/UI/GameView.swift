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
    
    enum AlertType {
        case quit
        case oponentQuit
    }
    
    @ObservedObject var gameCoordinator = GameCoordinator()
    @State var alertPresentation = PresentationState<AlertType>()
    
    @Binding var presented: Bool
    
    init(presented: Binding<Bool>) {
        self._presented = presented
    }
    
    private func quitTheGame() {
        gameCoordinator.quitTheGame()
        presented = false
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            ARViewContainer(coordinator: gameCoordinator)
                .edgesIgnoringSafeArea(.all)
                .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
                .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
            VStack {
                if gameCoordinator.infoMessage != nil {
                    Text(gameCoordinator.infoMessage!)
                        .fixedSize()
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
                    .padding()
                }
            }
            Button(action: { self.alertPresentation.value = .quit }) {
                Text("X")
                    .font(.title)
                    .foregroundColor(Color.gray)
                    .frame(width: 44, height: 44)
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .onReceive(gameCoordinator.$oponentDidLeaveTheGame) { leave in
            if leave { self.alertPresentation.value = .oponentQuit }
        }
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
        .alert(isPresented: $alertPresentation.presented) {
            if alertPresentation.value == .oponentQuit {
                return Alert(title: Text("You oponent left the game"),
                             message: nil,
                             dismissButton: .default(Text("OK")){
                                self.quitTheGame()
                            })
            }
            
            return Alert(title: Text("Do you really want to quit the game?"),
                        message: nil,
                        primaryButton: .destructive(Text("Quit")){
                            self.quitTheGame()
                        },
                        secondaryButton: .cancel())
        }
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
        GameView(presented: $presented)
    }
}
#endif
