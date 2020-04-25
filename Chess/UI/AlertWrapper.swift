//
//  AlertWrapper.swift
//  Chess
//
//  Created by Alexandr Gaidukov on 25.04.2020.
//  Copyright © 2020 Alexaner Gaidukov. All rights reserved.
//

import SwiftUI
import UIKit

struct AlertAction {
    var title: String
    var style: UIAlertAction.Style
    var handler: () -> () = {}
}

struct AlertConfiguration {
    var title: String?
    var message: String?
    var actions: [AlertAction]
}

struct AlertWrapper<Content: View>: UIViewControllerRepresentable {
    
    @Binding private var presented: Bool
    private let content: Content
    private let alertBuilder: () -> AlertConfiguration
    
    private func makeAlert(completion: @escaping () -> ()) -> UIAlertController {
        let config = alertBuilder()
        let alert = UIAlertController(title: config.title, message: config.message, preferredStyle: .alert)
        config.actions.forEach { action in
            let alertAction = UIAlertAction(title: action.title, style: action.style) { _ in
                action.handler()
                completion()
            }
            alert.addAction(alertAction)
        }
        return alert
    }
    
    init(presented: Binding<Bool>, content: Content, alertBuilder: @escaping () -> AlertConfiguration) {
        _presented = presented
        self.content = content
        self.alertBuilder = alertBuilder
    }
    
    func makeUIViewController(context: Context) -> UIHostingController<Content> {
        UIHostingController(rootView: content)
    }
    
    func updateUIViewController(_ uiViewController: UIHostingController<Content>, context: Context) {
        if presented && uiViewController.presentedViewController == nil {
            let alert = self.makeAlert {
                self.presented = false
            }
            uiViewController.present(alert, animated: true, completion: nil)
        }
    }
}

extension View {
    func choiseAlert(presented: Binding<Bool>, alert: @escaping () -> AlertConfiguration) -> some View {
        AlertWrapper(presented: presented, content: self, alertBuilder: alert)
    }
}
