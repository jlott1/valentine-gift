//
//  ViewController.swift
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

import UIKit
import AVFoundation

class ViewController: UIViewController, AVSpeechSynthesizerDelegate {

    // MARK: - Properties
    
    /// An array of text labels that we will be animated and spoken
    @IBOutlet var textLabels: [UILabel]!
    
    /// The speech synthesizer that will read our valentine
    var synthesizer: AVSpeechSynthesizer?
    
    /// The current line of the valentine being presented
    var currentLine = 0
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hideAllTheLabels()
        
        synthesizer = AVSpeechSynthesizer()
        synthesizer?.delegate = self
        
        showLabel(textLabels[0])
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Speech Synthesizer Delegate
    
    func speechSynthesizer(synthesizer: AVSpeechSynthesizer!, didFinishSpeechUtterance utterance: AVSpeechUtterance!) {
        
        // IMPORTANT: If this method isn't getting hit (and your poem only presents the first line) make sure you are using an iOS 7 simulator. As of the time of this comment the iOS 8 simulators do not support speech synthesis
        
        currentLine++
        
        if currentLine < textLabels.count {
            showLabel(textLabels[currentLine])
        }
        
    }

    // MARK: - Private methods
    
    func hideAllTheLabels() {
        for label in textLabels {
            label.alpha = 0.0
        }
    }
    
    func showLabel(label: UILabel) {
        
        speakLabelText(label)
        
        label.transform = CGAffineTransformMakeTranslation(0, 50)
        
        UIView.animateWithDuration(1.0, animations: { () -> Void in
            
            label.alpha = 1.0
            label.transform = CGAffineTransformIdentity
            
        })
        
    }
    
    func speakLabelText(label: UILabel) {
        let utterance = AVSpeechUtterance(string: label.text)
        utterance.rate = 0.2
        
        synthesizer?.speakUtterance(utterance)
    }
}

