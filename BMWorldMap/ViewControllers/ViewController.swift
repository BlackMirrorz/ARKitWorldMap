//
//  ViewController.swift
//  BMWorldMap
//
//  Created by Josh Robbins on 15/06/2018.
//  Copyright © 2018 BlackMirrorz. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController {
    
    // Our Data Object
    typealias BMWorlMapItem = [String: Data]
    let fileManager = FileManager.default
    var modelNode: SCNNode?
    var modelPlaced = false
    
    //---------------
    //MARK: - Outlets
    //---------------
    
    @IBOutlet weak var sessionLabelView: UIView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var mappingLabelView: UIView!
    @IBOutlet weak var mappingStatusLabel: UILabel!
    @IBOutlet weak var shareMapButton: BMRoundButton!
    
    //--------------------
    //MARK: - AR Variables
    //--------------------
    
    @IBOutlet var augmentedRealityView: ARSCNView!
    let augmentedRealitySession = ARSession()
    var configuration = ARWorldTrackingConfiguration()
    let updateQueue = DispatchQueue(label: "tech.blackMirrorz")
    var planeDetected = false
    
    //--------------------
    //MARK: - Focus Square
    //--------------------
    
    var focusSquare: FocusSquare?
    var canLoadFocusSquare = true
    var screenCenter: CGPoint { let bounds = self.augmentedRealityView?.bounds ; return CGPoint(x: bounds!.midX, y: bounds!.midY) }
    
    //------------------------
    // MARK: - View Life Cycle
    //------------------------
    
    override func viewDidLoad() {
        
        //1. Create A Tap Gesture To Place A Custom ARAnchor Which We Can Check To See If Gets Saved Later
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(placeAnchor(_:)))
        self.view.addGestureRecognizer(tapGesture)
        setupARSession()
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        NotificationCenter.default.addObserver(self, selector: #selector(importWorldMap(_:)), name: NSNotification.Name(rawValue: "MapReceived"), object: nil)
       
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
    }
    
    //------------------------
    //MARK: - User Interaction
    //------------------------
    
    /// Allows The User To Create An ARAnchor
    ///
    /// - Parameter gesture: UITapGestureRecognizer
    @objc func placeAnchor(_ gesture: UITapGestureRecognizer){
        
        //1. Get The Current Touch Location
        let currentTouchLocation = gesture.location(in: self.augmentedRealityView)
        
        //2. Perform An ARSCNHiteTest For Any Existing Or Perceived Horizontal Planes
        guard let hitTest = self.augmentedRealityView.hitTest(currentTouchLocation, types: [.existingPlane, .existingPlaneUsingExtent] ).first else { return }
        planeDetected = true
       
        //3. Create Our Anchor & Add It To The Scene
        let validAnchor = ARAnchor(name: "BMAnchor", transform: hitTest.worldTransform)
        self.augmentedRealitySession.add(anchor: validAnchor)
        
    }
    
    /// Scales The Model
    ///
    /// - Parameter gesture: UIPinchGestureRecognizer
    @objc func scaleModel(_ gesture: UIPinchGestureRecognizer) {
        
        guard let nodeToScale = modelNode else { return }
        
        if gesture.state == .changed {
            
            let pinchScaleX: CGFloat = gesture.scale * CGFloat((nodeToScale.scale.x))
            let pinchScaleY: CGFloat = gesture.scale * CGFloat((nodeToScale.scale.y))
            let pinchScaleZ: CGFloat = gesture.scale * CGFloat((nodeToScale.scale.z))
            let scaleVector = SCNVector3(Float(pinchScaleX), Float(pinchScaleY), Float(pinchScaleZ))
            nodeToScale.scale = scaleVector
            gesture.scale = 1
            
        }
        
        if gesture.state == .ended { }
        
    }
    
    //-----------------------
    //MARK: - ARSetup & Reset
    //-----------------------
    
    /// Runs The ARSession
    func setupARSession() {
        
        //1. Setup Our Session
        augmentedRealityView.session = augmentedRealitySession
        configuration.planeDetection = planeDetection(.Horizontal)
        configuration.environmentTexturing = .automatic
        augmentedRealityView.delegate = self
        augmentedRealityView.debugOptions = debug(.FeaturePoints)
        augmentedRealitySession.run(configuration, options: runOptions(.ResetAndRemove))
        augmentedRealitySession.delegate = self
       
        //2. Add Our Focus Square
        focusSquare = FocusSquare()
        self.augmentedRealityView?.scene.rootNode.addChildNode(focusSquare!)
        
        //3. Disable The IdleTimer
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    override var prefersStatusBarHidden : Bool { return true }
    
}
