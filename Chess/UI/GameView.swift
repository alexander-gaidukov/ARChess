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
        case colorChoise
        case figureTransform
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
    
    private func quitAlertConfiguration() -> AlertConfiguration {
        let cancel = AlertAction(title: "Cancel", style: .cancel)
        let quit = AlertAction(title: "Quit", style: .destructive) {
            self.quitTheGame()
        }
        return AlertConfiguration(title: "Do you really want to quit the game?", message: nil, actions: [cancel, quit])
    }
    
    private func oponentQuitAlertConfiguration() -> AlertConfiguration {
        let ok = AlertAction(title: "OK", style: .default) {
            self.quitTheGame()
        }
        return AlertConfiguration(title: "Your oponent left the game", message: nil, actions: [ok])
    }
    
    private func chooseColorAlertConfiguration() -> AlertConfiguration {
        let white = AlertAction(title: "White", style: .default) {
            self.gameCoordinator.playerColor = .white
        }
        let black = AlertAction(title: "Balck", style: .default) {
            self.gameCoordinator.playerColor = .black
        }
        return AlertConfiguration(title: "Choose color", message: nil, actions: [white, black])
    }
    
    private func transformFigureAlertConfiguration() -> AlertConfiguration {
        let queen = AlertAction(title: "Queen", style: .default) {
            self.gameCoordinator.figureTransformationCompletion?(.queen)
        }
        let rook = AlertAction(title: "Rook", style: .default) {
            self.gameCoordinator.figureTransformationCompletion?(.rook)
        }
        let bishop = AlertAction(title: "Bishop", style: .default) {
            self.gameCoordinator.figureTransformationCompletion?(.bishop)
        }
        let knight = AlertAction(title: "Knight", style: .default) {
            self.gameCoordinator.figureTransformationCompletion?(.knight)
        }
        return AlertConfiguration(title: "Choose figure type", message: nil, actions: [queen, rook, bishop, knight])
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
                    .frame(height: 60)
                    .buttonStyle(MainButtonStyle())
                    .padding()
                }
            }
            Button(action: { self.alertPresentation.value = .quit }) {
                Image(systemName: "xmark")
                    .imageScale(.large)
                    .foregroundColor(Color.gray)
                    .frame(width: 44, height: 44)
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .onReceive(gameCoordinator.$oponentDidLeaveTheGame) { leave in
            if leave { self.alertPresentation.value = .oponentQuit }
        }
        .onReceive(gameCoordinator.$askForTransformation) { ask in
            if ask { self.alertPresentation.value = .figureTransform }
        }
        .onReceive(gameCoordinator.$state) { _ in
            if self.gameCoordinator.askForFigureColor { self.alertPresentation.value = .colorChoise }
        }
        .choiseAlert(presented: $alertPresentation.presented) {
            switch self.alertPresentation.value! {
            case .quit:
                return self.quitAlertConfiguration()
            case .oponentQuit:
                return self.oponentQuitAlertConfiguration()
            case .colorChoise:
                return self.chooseColorAlertConfiguration()
            case .figureTransform:
                return self.transformFigureAlertConfiguration()
            }
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
