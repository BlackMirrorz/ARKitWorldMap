//
//  FocusSquare.swift
//  ARt
//
//  Created by Josh Robbins on 24/07/2018.
//  Copyright © 2018 Twinkl Limited. All rights reserved.
//


import Foundation
import ARKit

class FocusSquare: SCNNode {
   
    enum State: Equatable {
        case initializing
		case detecting(hitTestResult: ARHitTestResult, camera: ARCamera?)
    }
    
    let bmFocusSquare = BMFocusSquare()
    
    //-------------------
    // MARK: - Properties
    //-------------------
    
    /// The most recent position of the focus square based on the current state.
    var lastPosition: float3? {
        switch state {
        case .initializing: return nil
		case .detecting(let hitTestResult, _): return hitTestResult.worldTransform.translation
        }
    }
    
    var state: State = .initializing {
        didSet {
            guard state != oldValue else { return }
            
            switch state {
            case .initializing:
                displayAsBillboard()
				
			case let .detecting(hitTestResult, camera):
				if let planeAnchor = hitTestResult.anchor as? ARPlaneAnchor {
					displayAsClosed(for: hitTestResult, planeAnchor: planeAnchor, camera: camera)
					currentPlaneAnchor = planeAnchor
				} else {
					displayAsOpen(for: hitTestResult, camera: camera)
					currentPlaneAnchor = nil
				}
			}
        }
    }
    
    /// Indicates whether the segments of the focus square are disconnected.
    public var isOpen = false
    
    /// Indicates if the square is currently being animated.
    private var isAnimating = false
	
	/// Indicates if the square is currently changing its alignment.
	private var isChangingAlignment = false
	
	/// The focus square's current alignment.
	private var currentAlignment: ARPlaneAnchor.Alignment?
	
	/// The current plane anchor if the focus square is on a plane.
	private(set) var currentPlaneAnchor: ARPlaneAnchor?
    
    /// The focus square's most recent positions.
    private var recentFocusSquarePositions: [float3] = []
	
	/// The focus square's most recent alignments.
	private(set) var recentFocusSquareAlignments: [ARPlaneAnchor.Alignment] = []
    
    /// Previously visited plane anchors.
    private var anchorsOfVisitedPlanes: Set<ARAnchor> = []

    /// The primary node that controls the position of other `FocusSquare` nodes.
    private let positioningNode = SCNNode()
    
    //-----------------------
    // MARK: - Initialization
    //-----------------------
    
	override init() {
		super.init()
		opacity = 0.0
    
        // Always render focus square on top of other content.
        displayNodeHierarchyOnTop(true)
     
        self.addChildNode(bmFocusSquare)
      
        // Start the focus square as a billboard.
        displayAsBillboard()
	}
	
	required init?(coder aDecoder: NSCoder) {
        fatalError("\(#function) has not been implemented")
	}
    
    //----------------------
    // MARK: - Visualization
    //----------------------
    
    /// Hides the focus square.
    func hide() {
        guard action(forKey: "hide") == nil else { return }
        
        displayNodeHierarchyOnTop(false)
        runAction(.fadeOut(duration: 0.5), forKey: "hide")
    }
    
    /// Unhides the focus square.
    func unhide() {
        guard action(forKey: "unhide") == nil else { return }
        
        displayNodeHierarchyOnTop(true)
        runAction(.fadeIn(duration: 0.5), forKey: "unhide")
    }
    
    /// Displays the focus square parallel to the camera plane.
    private func displayAsBillboard() {
		simdTransform = matrix_identity_float4x4
		eulerAngles.x = .pi / 2
        simdPosition = float3(0, 0, -0.8)
        unhide()
       
    }

    /// Called when a surface has been detected.
    private func displayAsOpen(for hitTestResult: ARHitTestResult, camera: ARCamera?) {
      
		let position = hitTestResult.worldTransform.translation
        recentFocusSquarePositions.append(position)
		updateTransform(for: position, hitTestResult: hitTestResult, camera: camera)
        bmFocusSquare.focusSquareGeometry.firstMaterial?.diffuse.contents = UIImage(named: "focusSquareLocating")!
       
    }
    
    /// Called when a plane has been detected.
	private func displayAsClosed(for hitTestResult: ARHitTestResult, planeAnchor: ARPlaneAnchor, camera: ARCamera?) {
        
        anchorsOfVisitedPlanes.insert(planeAnchor)
		let position = hitTestResult.worldTransform.translation
        recentFocusSquarePositions.append(position)
		updateTransform(for: position, hitTestResult: hitTestResult, camera: camera)
        bmFocusSquare.focusSquareGeometry.firstMaterial?.diffuse.contents = UIImage(named: "focusSquareFound")!
        
    }
    
    //-----------------------
    // MARK: - Helper Methods
    //-----------------------

    /// Update the transform of the focus square to be aligned with the camera.
	private func updateTransform(for position: float3, hitTestResult: ARHitTestResult, camera: ARCamera?) {
		// Average using several most recent positions.
        recentFocusSquarePositions = Array(recentFocusSquarePositions.suffix(10))
		
        // Move to average of recent positions to avoid jitter.
        let average = recentFocusSquarePositions.reduce(float3(0), { $0 + $1 }) / Float(recentFocusSquarePositions.count)
        self.simdPosition = average
        self.simdScale = float3(scaleBasedOnDistance(camera: camera))
		
		// Correct y rotation of camera square.
        guard let camera = camera else { return }
        let tilt = abs(camera.eulerAngles.x)
        let threshold1: Float = .pi / 2 * 0.65
        let threshold2: Float = .pi / 2 * 0.75
        let yaw = atan2f(camera.transform.columns.0.x, camera.transform.columns.1.x)
        var angle: Float = 0
        
        switch tilt {
        case 0..<threshold1:
            angle = camera.eulerAngles.y
            
        case threshold1..<threshold2:
            let relativeInRange = abs((tilt - threshold1) / (threshold2 - threshold1))
            let normalizedY = normalize(camera.eulerAngles.y, forMinimalRotationTo: yaw)
            angle = normalizedY * (1 - relativeInRange) + yaw * relativeInRange
            
        default:
            angle = yaw
        }
		
		if state != .initializing {
			updateAlignment(for: hitTestResult, yRotationAngle: angle)
		}
    }
	
	private func updateAlignment(for hitTestResult: ARHitTestResult, yRotationAngle angle: Float) {
		// Abort if an animation is currently in progress.
		if isChangingAlignment {
			return
		}
		
		var shouldAnimateAlignmentChange = false
		
		let tempNode = SCNNode()
		tempNode.simdRotation = float4(0, 1, 0, angle)
		
		// Determine current alignment
		var alignment: ARPlaneAnchor.Alignment?
		if let planeAnchor = hitTestResult.anchor as? ARPlaneAnchor {
			alignment = planeAnchor.alignment
		} else if hitTestResult.type == .estimatedHorizontalPlane {
			alignment = .horizontal
		} else if hitTestResult.type == .estimatedVerticalPlane {
			alignment = .vertical
		}
		
		// add to list of recent alignments
		if alignment != nil {
			recentFocusSquareAlignments.append(alignment!)
		}
		
		// Average using several most recent alignments.
		recentFocusSquareAlignments = Array(recentFocusSquareAlignments.suffix(20))
		
		let horizontalHistory = recentFocusSquareAlignments.filter({ $0 == .horizontal }).count
		let verticalHistory = recentFocusSquareAlignments.filter({ $0 == .vertical }).count
		
		// Alignment is same as most of the history - change it
		if alignment == .horizontal && horizontalHistory > 15 ||
			alignment == .vertical && verticalHistory > 10 ||
			hitTestResult.anchor is ARPlaneAnchor {
			if alignment != currentAlignment {
				shouldAnimateAlignmentChange = true
				currentAlignment = alignment
				recentFocusSquareAlignments.removeAll()
			}
		} else {
			// Alignment is different than most of the history - ignore it
			alignment = currentAlignment
			return
		}
		
		if alignment == .vertical {
			tempNode.simdOrientation = hitTestResult.worldTransform.orientation
			shouldAnimateAlignmentChange = true
		}
		
		// Change the focus square's alignment
		if shouldAnimateAlignmentChange {
			performAlignmentAnimation(to: tempNode.simdOrientation)
		} else {
			simdOrientation = tempNode.simdOrientation
		}
	}
	
	private func normalize(_ angle: Float, forMinimalRotationTo ref: Float) -> Float {
		// Normalize angle in steps of 90 degrees such that the rotation to the other angle is minimal
		var normalized = angle
		while abs(normalized - ref) > .pi / 4 {
			if angle > ref {
				normalized -= .pi / 2
			} else {
				normalized += .pi / 2
			}
		}
		return normalized
	}

    /**
     Reduce visual size change with distance by scaling up when close and down when far away.
     
     These adjustments result in a scale of 1.0x for a distance of 0.7 m or less
     (estimated distance when looking at a table), and a scale of 1.2x
     for a distance 1.5 m distance (estimated distance when looking at the floor).
     */
	private func scaleBasedOnDistance(camera: ARCamera?) -> Float {
        guard let camera = camera else { return 1.0 }

        let distanceFromCamera = simd_length(simdWorldPosition - camera.transform.translation)
        if distanceFromCamera < 0.7 {
            return distanceFromCamera / 0.7
        } else {
            return 0.25 * distanceFromCamera + 0.825
		}
	}
    
   
	private func performAlignmentAnimation(to newOrientation: simd_quatf) {
		isChangingAlignment = true
		SCNTransaction.begin()
		SCNTransaction.completionBlock = {
			self.isChangingAlignment = false
		}
		SCNTransaction.animationDuration = 0.5
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
		simdOrientation = newOrientation
		SCNTransaction.commit()
	}
    

    /// Sets the rendering order of the `positioningNode` to show on top or under other scene content.
    func displayNodeHierarchyOnTop(_ isOnTop: Bool) {
        // Recursivley traverses the node's children to update the rendering order depending on the `isOnTop` parameter.
        func updateRenderOrder(for node: SCNNode) {
            node.renderingOrder = isOnTop ? 2 : 0
            
            for material in node.geometry?.materials ?? [] {
                material.readsFromDepthBuffer = !isOnTop
            }
            
            for child in node.childNodes {
                updateRenderOrder(for: child)
            }
        }
        
        updateRenderOrder(for: positioningNode)
    }
}
