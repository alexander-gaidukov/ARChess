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
    
    @Environment(\.presentationMode) private var presentationMode
    
    @ObservedObject private var advertiser = GameAdvertiser()
    
    var body: some View {
        Text(advertiser.sessionMessage)
            .font(.title)
            .onAppear { self.advertiser.start() }
            .onDisappear { self.advertiser.stop() }
            .onReceive(advertiser.$completed) { completed in
                if completed { self.presentationMode.wrappedValue.dismiss() }
            }
            .alert(isPresented: $advertiser.shouldShowConfirmation) {
                Alert(title: Text("\(self.advertiser.candidatePeerID!.displayName) wants to play with you"),
                      primaryButton: .default(Text("Accept")) {
                        DispatchQueue.main.async {
                            self.advertiser.acceptInvitation()
                        }
                    }, secondaryButton: .destructive(Text("Decline")) {
                        DispatchQueue.main.async {
                            self.advertiser.declineInvitation()
                        }
                    })
            }
    }
}

#if DEBUG
struct HostGameView_Previews: PreviewProvider {
    static var previews: some View {
        HostGameView()
    }
}
#endif
