//
//  ArtGallery+FocusSquare.swift
//  BMWorldMap
//
//  Created by Josh Robbins on 15/06/2018.
//  Copyright © 2018 BlackMirrorz. All rights reserved.
//

import Foundation

extension ViewController{
    
    //------------------
    //MARK: Focus Square
    //------------------
    
    /// Updates The Focus Square
    func updateFocusSquare() {
        
        if let validFocusSquare = focusSquare{
            
            if modelPlaced {
                focusSquare?.removeFromParentNode()
                focusSquare = nil
                return
            }
            
            if  let camera = self.augmentedRealityView?.session.currentFrame?.camera, case .normal = camera.trackingState,
                let result = self.augmentedRealityView?.smartHitTest(screenCenter) {
               
                updateQueue.async {
                    
                    if self.canLoadFocusSquare{
                        self.augmentedRealityView?.scene.rootNode.addChildNode(validFocusSquare)
                        self.focusSquare?.state = .detecting(hitTestResult: result, camera: camera)
                        
                    }
                }
                
            } else {
                
                updateQueue.async {
                    
                    if self.canLoadFocusSquare{
                        validFocusSquare.state = .initializing
                        self.augmentedRealityView?.pointOfView?.addChildNode(validFocusSquare)
                    }
                }
            }
        }
    }
}
