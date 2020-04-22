//
//  Tail.swift
//  Chess
//
//  Created by Alexandr Gaidukov on 14.04.2020.
//  Copyright © 2020 Alexaner Gaidukov. All rights reserved.
//

import RealityKit
import UIKit

extension UIColor {
    var material: Material {
        UnlitMaterial(color: self)
    }
}

final class Tail: Entity, HasModel {
    
    enum Color {
        case black
        case white
        var uiColor: UIColor {
            switch self{
            case .black:
                return #colorLiteral(red: 0.1176470588, green: 0.1176470588, blue: 0.1176470588, alpha: 1)
            case .white:
                return #colorLiteral(red: 0.8823529412, green: 0.8823529412, blue: 0.8823529412, alpha: 1)
            }
        }
    }
    
    init(color: Color) {
        super.init()
        self.model = ModelComponent(mesh: .generateBox(size: [1, 0.1, 1]), materials: [color.uiColor.material])
    }
    
    required init() {
        fatalError("init() has not been implemented")
    }
}
