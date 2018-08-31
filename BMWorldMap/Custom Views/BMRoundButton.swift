//
//  BMRoundButton.swift
//  BMWorldMap
//
//  Created by Josh Robbins on 31/08/2018.
//  Copyright © 2018 BlackMirrorz. All rights reserved.
//

import UIKit

@IBDesignable public class BMRoundButton: UIButton {
    
    @IBInspectable var borderColor: UIColor = .white{
        didSet {
            layer.borderColor = borderColor.cgColor
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 2.0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = 0.5 * bounds.size.width
            
        }
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        clipsToBounds = true
    }
}
