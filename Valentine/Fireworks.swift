//
//  Fireworks.swift
//  Valentine
//
//  Created by Jonathan Lott on 1/23/18.
//  Copyright © 2018 Chris Voss. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import QuartzCore

struct Fireworks {
    var rootLayer:CALayer = CALayer()
    var emitterLayer:CAEmitterLayer = CAEmitterLayer()
    var mortor:CAEmitterLayer = CAEmitterLayer()
    var soundPlayer = SoundPlayer()
    init() {}
    
    // https://stackoverflow.com/questions/19274789/how-can-i-change-image-tintcolor-in-ios-and-watchkit
    func image(with image: UIImage!, color1: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        let context: CGContext = UIGraphicsGetCurrentContext()!
        context.translateBy(x: 0, y: image.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.setBlendMode(.normal)
        let rect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        context.clip(to: rect, mask: image.cgImage!)
        color1.setFill()
        context.fill(rect)
        let newImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    /*
     Combination of these two references
     https://developer.apple.com/library/content/samplecode/Fireworks/Introduction/Intro.html#//apple_ref/doc/uid/DTS40009114
     http://www.knowstack.com/swift-caemittercell-caemitterlayer-fireworks/
     https://github.com/tapwork/iOS-Particle-Fireworks
     with a little help from here
     https://stackoverflow.com/questions/4706272/tips-on-writing-a-calayer-subclass-for-both-mac-and-ios/4706397
     */
    func createFireworks(in view: UIView) {
        //Create the root layer
        //        rootLayer = CALayer()
        //Set the root layer's attributes
        rootLayer.bounds = view.bounds;
        var color: CGColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0).cgColor
        rootLayer.backgroundColor = color
        //Load the spark image for the particle
        let image = UIImage(named: "tspark")
        //        let newImage = image!.withRenderingMode(.alwaysTemplate)
        let coloredImage = self.image(with: image, color1:  view.backgroundColor ?? .white)
        
        let img = coloredImage?.cgImage
        //        mortor = CAEmitterLayer()
        mortor.emitterPosition = CGPoint(x: 320, y: -200)
        mortor.renderMode = kCAEmitterLayerAdditive
        //Invisible particle representing the rocket before the explosion
        let rocket = CAEmitterCell()
        rocket.emissionLongitude = .pi / 2
        rocket.emissionLatitude = 0
        rocket.lifetime = 1.6
        rocket.birthRate = 1
        rocket.velocity = 400
        rocket.velocityRange = 100
        rocket.yAcceleration = -200
        rocket.emissionRange = .pi / 4
        color = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5).cgColor
        rocket.color = color
        rocket.redRange = 0.5
        rocket.greenRange = 0.5
        rocket.blueRange = 0.5
        //Name the cell so that it can be animated later using keypath
        rocket.name = "rocket"
        //Flare particles emitted from the rocket as it flys
        let flare = CAEmitterCell()
        flare.contents = img
        flare.emissionLongitude = (4 * .pi) / 2
        flare.scale = 0.4
        flare.velocity = 100
        flare.birthRate = 45
        flare.lifetime = 1.5
        flare.yAcceleration = -350
        flare.emissionRange = .pi / 7
        flare.alphaSpeed = -0.7
        flare.scaleSpeed = -0.1
        flare.scaleRange = 0.1
        flare.beginTime = 0.01
        flare.duration = 0.7
        //The particles that make up the explosion
        let firework = CAEmitterCell()
        firework.contents = img
        firework.birthRate = 9999
        firework.scale = 0.6
        firework.velocity = 130
        firework.lifetime = 2
        firework.alphaSpeed = -0.2
        firework.yAcceleration = -80
        firework.beginTime = 1.5
        firework.duration = 0.1
        firework.emissionRange = 2 * .pi
        firework.scaleSpeed = -0.1
        firework.spin = 2
        //Name the cell so that it can be animated later using keypath
        firework.name = "firework"
        //preSpark is an invisible particle used to later emit the spark
        let preSpark = CAEmitterCell()
        preSpark.birthRate = 80
        preSpark.velocity = firework.velocity * 0.70
        preSpark.lifetime = 1.7
        preSpark.yAcceleration = firework.yAcceleration * 0.85
        preSpark.beginTime = (firework.beginTime - 0.2)
        preSpark.emissionRange = firework.emissionRange
        preSpark.greenSpeed = 100
        preSpark.blueSpeed = 100
        preSpark.redSpeed = 100
        //Name the cell so that it can be animated later using keypath
        preSpark.name = "preSpark"
        //The 'sparkle' at the end of a firework
        let spark = CAEmitterCell()
        spark.contents = img
        spark.lifetime = 0.05
        spark.yAcceleration = -250
        spark.beginTime = 0.8
        spark.scale = 0.4
        spark.birthRate = 10
        preSpark.emitterCells = [spark]
        rocket.emitterCells = [flare, firework, preSpark]
        mortor.emitterCells = [rocket]
        
        //slow it down for effect
        mortor.speed = 0.9
        
        //flip rootLayer
        rootLayer.sublayerTransform = CATransform3DMakeScale(1.0, -1.0, 1.0);
        
        rootLayer.addSublayer(mortor)
        
        //Set the view's layer to the base layer
        view.layer.insertSublayer(rootLayer, at: 0)
        
        //Force the view to update
        view.setNeedsDisplay()
        
        let randomDelay = Int(arc4random_uniform(2))
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(randomDelay)) {
            self.soundPlayer.playSound(withName: "Fireworks-Sounds.m4v")
        }
    }
    
    func destroyFireworks() {
        rootLayer.removeFromSuperlayer()
        soundPlayer.stopSound()
    }
}
