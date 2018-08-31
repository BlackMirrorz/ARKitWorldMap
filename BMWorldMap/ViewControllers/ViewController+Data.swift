//
//  ViewController+Data.swift
//  BMWorldMap
//
//  Created by Josh Robbins on 31/08/2018.
//  Copyright © 2018 BlackMirrorz. All rights reserved.
//

import Foundation
import ARKit

extension ViewController{
    
    //-----------------------------------
    // MARK: - World Map Saving & Loading
    //-----------------------------------
    
    /// Saves An ARWorldMap To The Documents Directory And Allows It To Be Sent As A Custom FileType
    @IBAction func saveWorldMap(){
        
        //1. Attempt To Get The World Map From Our ARSession
        augmentedRealitySession.getCurrentWorldMap { worldMap, error in
            
            guard let mapToShare = worldMap else { print("Error: \(error!.localizedDescription)"); return }
            
            //2. We Have A Valid ARWorldMap So Save It To The Documents Directort
            guard let data = try? NSKeyedArchiver.archivedData(withRootObject: mapToShare, requiringSecureCoding: true) else { fatalError("Can't Encode Map") }
            
            do {
                
                //a. Create An Identifier For Our Map
                let mapIdentifier = "BlackMirrorzMap"
                
                //b. Create An Object To Save The Name And WorldMap
                var contentsToSave = BMWorlMapItem()
                
                //c. Get The Documents Directory
                let documentDirectory = try self.fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
                
                //d. Create The File Name
                let savedFileURL = documentDirectory.appendingPathComponent("/\(mapIdentifier).bmarwp")
                
                //e. Set The Data & Save It To The Documents Directory
                contentsToSave[mapIdentifier] = data
                
                do{
                    let archive = try NSKeyedArchiver.archivedData(withRootObject: contentsToSave, requiringSecureCoding: true)
                    try archive.write(to: savedFileURL)
                    
                    //f. Show An Alert Controller To Share The Item
                    let activityController = UIActivityViewController(activityItems: ["Check Out My Custom ARWorldMap", savedFileURL], applicationActivities: [])
                    self.present(activityController, animated: true)
                    
                    print("Succesfully Saved Custom ARWorldMap")
                    
                }catch{
                    
                    print("Error Generating WorldMap Object == \(error)")
                }
                
            } catch {
                
                print("Error Saving Custom WorldMap Object == \(error)")
            }
            
        }
    }
    
    
    /// Imports A WorldMap From A Custom File Type
    ///
    /// - Parameter notification: NSNotification)
    @objc public func importWorldMap(_ notification: NSNotification){
        
        //1. Remove All Our Content From The Hierachy
        self.augmentedRealityView.scene.rootNode.enumerateChildNodes { (existingNode, _) in existingNode.removeFromParentNode() }
        
        //2. Check That Our UserInfo Is A Valid URL
        if let url = notification.userInfo?["MapData"] as? URL{
            
            //3. Convert Our URL To Data
            do{
                let data = try Data(contentsOf: url)
                
                //4. Unarchive Our Data Which Is Of Type [String: Data] A.K.A BMWorlMapItem
                if let mapItem = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as! BMWorlMapItem,
                    let archiveName = mapItem.keys.first,
                    let mapData = mapItem[archiveName] {
                    
                    //5. Get The Map Data & Log The Anchors To See If It Includes Our BMAnchor Which We Saved Earlier
                    if  let unarchivedMap = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [ARWorldMap.classForKeyedUnarchiver()], from: mapData),
                        let worldMap = unarchivedMap as? ARWorldMap {
                        
                        print("Extracted BMWorldMap Item Named = \(archiveName)")
                        
                        worldMap.anchors.forEach { (anchor) in if let name = anchor.name { print ("Anchor Name == \(name)") } }
                        
                        //5. Restart Our Session & Reset Out Variables
                        modelNode = nil
                        modelPlaced = false
                        planeDetected = false
                        
                        let configuration = ARWorldTrackingConfiguration()
                        configuration.planeDetection = .horizontal
                        configuration.initialWorldMap = worldMap
                        self.augmentedRealityView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
                    }
                    
                }
                
            }catch{
                
                print("Error Extracting Data == \(error)")
            }
        }
    }
}
