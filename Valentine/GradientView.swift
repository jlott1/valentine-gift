//
//  GradientView.swift
//  Valentine
//
// Copyright (c) 2015 Chris Voss (http://chrisvoss.me)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import UIKit

/// Gradient view inspired by post at http://www.thinkandbuild.it/building-custom-ui-element-with-ibdesignable/
@IBDesignable class GradientView: UIView {
    
    @IBInspectable var fromColor: UIColor = UIColor.darkGrayColor() {
        didSet {
            setupView()
        }
    }
    
    @IBInspectable var toColor: UIColor = UIColor.blackColor() {
        didSet {
            setupView()
        }
    }
    
    // Setup the view appearance
    private func setupView(){
        let colors: Array = [fromColor.CGColor, toColor.CGColor]
        
        gradientLayer.colors = colors
        
        gradientLayer.locations = [0.3, 1.0]
        
        self.setNeedsDisplay()
    }
    
    // Helper to return the main layer as CAGradientLayer
    var gradientLayer: CAGradientLayer {
        return layer as CAGradientLayer
    }
    
    override class func layerClass() -> AnyClass {
        return CAGradientLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupView()
    }
}