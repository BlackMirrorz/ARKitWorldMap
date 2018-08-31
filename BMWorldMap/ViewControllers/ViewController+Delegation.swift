//
//  ViewController+Delegation.swift
//  BMWorldMap
//
//  Created by Josh Robbins on 31/08/2018.
//  Copyright © 2018 BlackMirrorz. All rights reserved.
//

import Foundation
import ARKit

//-------------------------
//MARK: - ARSCNViewDelegate
//-------------------------

extension ViewController: ARSCNViewDelegate{
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        //1. Update The Focus Square & Tracking Status
        DispatchQueue.main.async {
            
            //a. Update The Focus Square
            self.updateFocusSquare()
            
            //b. Update The Tracking Status
            guard let camera = self.augmentedRealitySession.currentFrame?.camera else { return }
            self.statusLabel.text = camera.trackingState.description
            
            //c. If We Have Nothing To Report Then Hide The Status View
            if let validSessionText = self.statusLabel.text{
                
                self.sessionLabelView.isHidden = validSessionText.isEmpty
            }
 
        }
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        if modelPlaced { return SCNNode() }
        
        //1. Check We Have Our BMAnchor
        if let name = anchor.name, name == "BMAnchor", modelNode == nil {
            
            //2. Create Our Model Node & Add It To The Hierachy
            modelNode = SCNNode()
            
            guard let sceneURL = SCNScene(named: "art.scnassets/wavingState.dae") else { return nil }
            
            for childNode in sceneURL.rootNode.childNodes { modelNode?.addChildNode(childNode) }
            
            modelPlaced = true
            
            return modelNode
            
        }else{
            
            return SCNNode()
        }
    }
}

//-------------------------
//MARK: - ARSessionDelegate
//-------------------------

extension ViewController: ARSessionDelegate{
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        //1. Update The Mapping Status Label
        mappingStatusLabel.text = frame.worldMappingStatus.description
        setShareButtonFrom(frame.worldMappingStatus)
        
    }
    
    /// Enables Or Disables The Share Map Button & Visualizes The Status
    ///
    /// - Parameter status: ARFrane.WorldMappingStatus
    func setShareButtonFrom(_ status: ARFrame.WorldMappingStatus){
        
        shareMapButton.layer.borderColor = UIColor.red.cgColor
        
        switch status {
            
        case .notAvailable, .limited:
            shareMapButton.isEnabled = false
        case .extending, .mapped:
            
            if planeDetected{
                shareMapButton.isEnabled = true
                shareMapButton.layer.borderColor = UIColor.green.cgColor
            }
            
        }
        
    }
}
