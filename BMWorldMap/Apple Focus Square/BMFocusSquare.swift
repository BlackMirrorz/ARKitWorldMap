//
//  BMFocusSquare.swift
//  BMWorldMap
//
//  Created by Josh Robbins on 15/06/2018.
//  Copyright © 2018 BlackMirrorz. All rights reserved.
//

import Foundation
import ARKit

class BMFocusSquare: SCNNode{
    
    var focusSquareGeometry: SCNPlane!
    
    override init() {
        
        super.init()
        
        guard let focusSquareScene = SCNScene(named: "art.scnassets/FocusSquare.scn"),
              let focusSquare = focusSquareScene.rootNode.childNode(withName: "FocusSquare", recursively: false)
        else { return }
        
        focusSquareGeometry = focusSquare.geometry as? SCNPlane
        
        self.addChildNode(focusSquare)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
