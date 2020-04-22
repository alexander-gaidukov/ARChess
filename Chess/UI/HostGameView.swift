//
//  HostGameView.swift
//  Chess
//
//  Created by Alexandr Gaidukov on 19.04.2020.
//  Copyright © 2020 Alexaner Gaidukov. All rights reserved.
//

import SwiftUI

struct HostGameView: View {
    
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject private var advertiser = GameAdvertiser()
    
    @State var connectionConfirmation = PresentationState<String>()
    
    var body: some View {
        Text(advertiser.sessionMessage)
            .font(.title)
            .onAppear { self.advertiser.start() }
            .onDisappear { self.advertiser.stop() }
            .onReceive(advertiser.$completed) { completed in
                if completed { self.presentationMode.wrappedValue.dismiss() }
            }
            .onReceive(advertiser.$candidatePeerID) { candidate in
                self.connectionConfirmation.value = candidate?.displayName
            }
            .alert(isPresented: $connectionConfirmation.presented) {
                Alert(title: Text("\(self.connectionConfirmation.value ?? "") wants to play with you"),
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
