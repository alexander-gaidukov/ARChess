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
    
    init(color: UIColor) {
        super.init()
        self.model = ModelComponent(mesh: .generateBox(size: [1, 0.1, 1]), materials: [color.material])
    }
    
    required init() {
        fatalError("init() has not been implemented")
    }
}
