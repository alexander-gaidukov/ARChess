//
//  File.swift
//  Chess
//
//  Created by Alexandr Gaidukov on 15.04.2020.
//  Copyright © 2020 Alexaner Gaidukov. All rights reserved.
//

import RealityKit
import UIKit

final class FocusEntity: Entity, HasModel {
    
    enum FocusType {
        case focus
        case error
        
        var color: UIColor {
            switch self {
            case .focus:
                return #colorLiteral(red: 0.9686274529, green: 0.78039217, blue: 0.3450980484, alpha: 0.7)
            case .error:
                return #colorLiteral(red: 1, green: 0, blue: 0, alpha: 0.7)
            }
        }
    }
    
    init(type: FocusType) {
        super.init()
        model = ModelComponent(mesh: .generatePlane(width: 1, depth: 1), materials: [type.color.material])
    }
    
    required init() {
        fatalError("init() has not been implemented")
    }
}
