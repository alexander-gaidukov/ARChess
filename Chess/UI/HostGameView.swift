//
//  HostGameView.swift
//  Chess
//
//  Created by Alexandr Gaidukov on 19.04.2020.
//  Copyright © 2020 Alexaner Gaidukov. All rights reserved.
//

import SwiftUI

extension Binding where Value == Bool {
    var negate: Binding<Bool> {
        Binding<Bool>(get: { !self.wrappedValue }, set: { self.wrappedValue = !$0 })
    }
}

struct HostGameView: View {
    
    @ObservedObject private var advertiser: GameAdvertiser
    
    init(presented: Binding<Bool>, gameSession: GameSession) {
        advertiser = GameAdvertiser(completed: presented.negate, gameSession: gameSession)
    }
    
    var body: some View {
        Text(advertiser.sessionMessage)
            .font(.title)
            .onAppear { self.advertiser.start() }
            .onDisappear { self.advertiser.stop() }
    }
}

#if DEBUG
struct HostGameView_Previews: PreviewProvider {
    @State static var presented: Bool = true
    static var previews: some View {
        HostGameView(presented: $presented, gameSession: GameSession())
    }
}
#endif
