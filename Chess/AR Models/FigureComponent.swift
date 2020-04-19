//
//  FigureComponent.swift
//  Chess
//
//  Created by Alexandr Gaidukov on 15.04.2020.
//  Copyright © 2020 Alexaner Gaidukov. All rights reserved.
//

import RealityKit

struct FigureComponent: Component, Codable {
    var type: FigureType
    var color: FigureColor
}

extension Entity {
    var figureComponent: FigureComponent? {
        get {
            components[FigureComponent.self]
        }
        set {
            components[FigureComponent.self] = newValue
        }
    }
    
    var figure: Figure? {
        get {
            figureComponent.map { Figure(type: $0.type, color: $0.color) }
        }
        set {
            figureComponent = newValue.map { FigureComponent(type: $0.type, color: $0.color) }
        }
    }
}
