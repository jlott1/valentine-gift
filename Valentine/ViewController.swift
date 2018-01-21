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
import Speech
import QuartzCore

class Phrase {
    static let kThresholdDelay = 1.0
    var words: String = ""
    var delay: TimeInterval = 0
    init() {}
}

class ViewController: UIViewController, AVSpeechSynthesizerDelegate {

    // MARK: - Properties
    
    /// An array of text labels that we will be animated and spoken
    var textLabels: [UILabel]!
    
    /// The speech synthesizer that will read our valentine
    var synthesizer: AVSpeechSynthesizer?
    
    /// The current line of the valentine being presented
    var currentLine = 0
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var stackView: UIStackView!
    @IBOutlet var resetButton: UIButton!
    @IBOutlet var chooseSongButton: UIButton!
    
    // speech recognition
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var microphoneButton: UIButton!
    @IBOutlet var titleLabel: UILabel!
    
    fileprivate let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))!
    
    fileprivate var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    fileprivate var recognitionTask: SFSpeechRecognitionTask?
    fileprivate let audioEngine = AVAudioEngine()
    fileprivate var transcription: SFTranscription?
    var utterances: [AVSpeechUtterance] = []
    
    @IBOutlet var creditsLabel: UILabel!
    // Magic !!!
    var fireworks: [Fireworks] = []
    var music: SoundPlayer = SoundPlayer()
    var selectedTrackId = iTunesTrackIDs.JonathanMyBride
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resetButton.isHidden = true
        scrollView.isHidden = true
        creditsLabel.isHidden = true
        
        synthesizer = AVSpeechSynthesizer()
        synthesizer?.delegate = self
        
        setupSpeechRecognizer()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func finishedTranscribing() {
        currentLine = 0
        // remove all labels
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        // hide text view and show scroll view
        textView.isHidden = true
        scrollView.isHidden = false
        titleLabel.isHidden = true
        resetButton.isHidden = false
        microphoneButton.isHidden = true
        
       startSpeechReplay()
    }
    
    func startSpeechReplay() {
        if let segments = transcription?.segments, segments.count > 0 {
            
            var previousTimestamp : TimeInterval = 0
            var previousSegment: SFTranscriptionSegment? = nil
            var phraseWords : String = ""
            var phrases: [Phrase] = []
            var phraseDelay : TimeInterval = 0
            var phrase : Phrase = Phrase()
            
            segments.forEach({
                let delay = $0.timestamp - previousTimestamp
                print("word '\($0.substring)'")
                print("delay (\(delay)) between '\(previousSegment?.substring ?? "")' and '\($0.substring)'")
                if delay > Phrase.kThresholdDelay || $0 == segments.first {
                    
                    print("completed phrase '\(phrase.words)' with delay (\(phrase.delay))")
                    if phrase.words.count > 0 {
                        phrases.append(phrase)
                    }
                    
                    // create a new phrase
                    phrase = Phrase()
                    phrase.delay = delay
                    phrase.words = phrase.words + (phrase.words.count > 0 ? " " : "") + $0.substring
                    
                    if $0 == segments.last && phrase.words.count > 0 {
                        phrases.append(phrase)
                    }
                }
                else if segments.last == $0 {
                    phrase.words = phrase.words + (phrase.words.count > 0 ? " " : "") + $0.substring
                    phrase.delay = delay
                    if phrase.words.count > 0 {
                        phrases.append(phrase)
                    }
                }
                else {
                    //                    print("no delay \(diff)")//print("delay (\(diff)) between \(previousSegment) and \($0)")
                    phrase.words = phrase.words + (phrase.words.count > 0 ? " " : "") + $0.substring
                }
                previousTimestamp = $0.timestamp
                previousSegment = $0
            })
            
//            segments.forEach({
//                let delay = $0.timestamp - previousTimestamp
//                print("delay (\(delay)) between '\(previousSegment?.substring ?? "")' and '\($0.substring)'")
//                if delay > Phrase.kThresholdDelay {
//                    if segments.last == $0 {
//                        phraseWords = phraseWords + (phraseWords.count > 0 ? " " : "") + $0.substring
//                    }
//                    // start a new phrase
//                    if phraseWords.count > 0 {
//                        phraseDelay = delay//$0.timestamp - phraseDelay
//                        let phrase = Phrase(words: phraseWords, delay: phraseDelay)
//                        phrases.append(phrase)
//                        print("new phrase is '\(phrase.words)' with delay (\(phrase.delay))")
//                    }
//
//                    // reset phrase words
//                    phraseWords = $0.substring
//                }
//                else if segments.last == $0 {
//                    phraseWords = phraseWords + (phraseWords.count > 0 ? " " : "") + $0.substring
//                    // start a new phrase
//                    if phraseWords.count > 0 {
//                        phraseDelay = delay//$0.timestamp - phraseDelay
//                        let phrase = Phrase(words: phraseWords, delay: phraseDelay)
//                        phrases.append(phrase)
//                        print("new phrase is '\(phrase.words)' with delay (\(phrase.delay))")
//                    }
//                }
//                else {
////                    print("no delay \(diff)")//print("delay (\(diff)) between \(previousSegment) and \($0)")
//                    phraseWords = phraseWords + (phraseWords.count > 0 ? " " : "") + $0.substring
//                }
//                print("words = '\(phraseWords)'")
//                previousTimestamp = $0.timestamp
//                previousSegment = $0
//            })
            
            // speak segments by mapping segments to utterances
//            let utterances = segments.map({ (segment) -> AVSpeechUtterance in
//                let utterance = AVSpeechUtterance(string: segment.substring)
//                utterance.rate = 0.3
//                utterance.preUtteranceDelay = segment.timestamp
//                return utterance
//            })

            let utterances = phrases.map({ (phrase) -> AVSpeechUtterance in
                let utterance = AVSpeechUtterance(string: phrase.words)
                utterance.rate = 0.3
                utterance.preUtteranceDelay = phrase.delay
                return utterance
            })
            self.utterances = utterances
            
            // now speak
            for utterance in utterances {
                synthesizer?.speak(utterance)
            }
            
            music.playiTunesSongPreview(withId: selectedTrackId.rawValue, completion: { (results, error) in
                if let results = results {
                    //show label and animate it in
                    let label = self.creditsLabel!
                    label.text = "Music\n \(results.trackDescription())"
                    self.creditsLabel.isHidden = false
                    
                    label.transform = CGAffineTransform(translationX: 0, y: 50)
                    label.alpha = 0.0
                    
                    UIView.animate(withDuration: 1.0, animations: { () -> Void in
                        label.alpha = 1.0
                        label.transform = CGAffineTransform.identity
                    })
                }
            })
        }
    }
    // MARK: - Speech Synthesizer Delegate
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        // on start of speech let's show a label with the text
        showLabel(with: utterance.speechString)
        if (utterance == utterances.last) {
            createFireworks()
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        
        
    }
    @IBAction func chooseSongButtonTapped(_ sender: Any) {
        let alert = UIAlertController(title: "Choose A Song", message: "This song will play during playback of your speech.", preferredStyle: UIAlertControllerStyle.actionSheet)
        for option in iTunesTrackIDs.allValues {
            let option = UIAlertAction(title: option.trackShortName(), style: UIAlertActionStyle.default, handler: { (action) in
                self.selectedTrackId = option
            })
            alert.addAction(option)
        }
        let option = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
        alert.addAction(option)
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func resetButtonTapped(_ sender: Any) {
        scrollView.isHidden = true
        titleLabel.isHidden = false
        textView.isHidden = false
        microphoneButton.isHidden = false
        microphoneButton.isEnabled = true
        
        resetButton.isHidden = true
        chooseSongButton.isHidden = false
        
        destroyFireworks()
        music.stopSound()
    }
    // MARK: - Private methods

    func newLabelWithText(text: String) -> UILabel {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 30, weight: UIFontWeightThin )
        label.text = text
        label.numberOfLines = 0
        label.textAlignment = .center
        
        return label
    }
    
    func showLabel(with text: String) {
        
        let label = newLabelWithText(text: text)
        // add it to the stack view
        stackView.addArrangedSubview(label)
        
        label.transform = CGAffineTransform(translationX: 0, y: 50)
        label.alpha = 0.0
        self.stackView.layoutIfNeeded()

        UIView.animate(withDuration: 1.0, animations: { () -> Void in
            
            label.alpha = 1.0
            label.transform = CGAffineTransform.identity
//            let bottomOffset = CGPoint(x: 0, y: self.scrollView.contentSize.height - self.scrollView.bounds.size.height)
//            print("bottom offset = \(bottomOffset)")
//            print("should scroll? \(bottomOffset) > \(self.scrollView.bounds.size.height), label frame \(label.frame), container frame \(label.superview)")
            self.scrollView.scrollRectToVisible(label.frame.insetBy(dx: 0, dy: -80), animated: false)
        })
        
    }
    
    func speakLabelText(_ label: UILabel) {
        let utterance = AVSpeechUtterance(string: label.text!)
        utterance.rate = 0.3
        
        synthesizer?.speak(utterance)
    }
}

extension ViewController : SFSpeechRecognizerDelegate {
    func setupSpeechRecognizer() {
        microphoneButton.isEnabled = false
        
        speechRecognizer.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            
            var isButtonEnabled = false
            
            switch authStatus {
            case .authorized:
                isButtonEnabled = true
                
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
                
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
                
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
            
            OperationQueue.main.addOperation() {
                self.microphoneButton.isEnabled = isButtonEnabled
            }
        }
    }
    
    
    @IBAction func microphoneTapped(_ sender: AnyObject) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            microphoneButton.isEnabled = false
            microphoneButton.setTitle("Start Recording", for: .normal)
        } else {
            chooseSongButton.isHidden = true
            startRecording()
            microphoneButton.setTitle("Stop Recording", for: .normal)
        }
    }
    
    func startRecording() {
        
        if recognitionTask != nil {  //1
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()  //2
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()  //3
        
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }  //4
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        } //5
        
        recognitionRequest.shouldReportPartialResults = true  //6
        var date = Date()
        var delays: [TimeInterval] = [];
        var phrases: [Phrase] = [];
        var words = [String]()
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in  //7
            
            var isFinal = false  //8
            
            if result != nil {
                let wordsLength = words.count
                
                let delay = Date().timeIntervalSince(date)
                date = Date()
                print("delay = \(delay), isFinal = \(result?.isFinal)")
                delays.append(delay)
                
//                if delay > Phrase.kThresholdDelay && wordsLength > 0 {
//                    var phrase = Phrase()
//                    phrase.words.append(contentsOf: words)
//                    phrases.append(phrase)
//                    words.removeAll()
//                    print("new phrase words \(phrase.words)")
//                }
//
                if let word = result?.bestTranscription.segments.last?.substring, (words.last == nil || word != words.last) {
                    //                    print("segments: \(result?.bestTranscription.segments)")
                    words.append(word)
                }
                
                self.textView.text = result?.bestTranscription.formattedString  //9
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {  //10
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.microphoneButton.isEnabled = true
                
                print("segment times = \((result?.bestTranscription.segments as? NSArray)?.value(forKey: "timestamp"))")
                
                var previousTimestamp : TimeInterval = 0
                var previousSegment: SFTranscriptionSegment? = nil
                var phraseWords : [String] = []
//                if let segments = result?.bestTranscription.segments {
//                    segments.forEach({
//                        let diff = $0.timestamp - previousTimestamp
//                        if diff > Phrase.kThresholdDelay {
//                            print("delay (\(diff)) between \(previousSegment?.substring ?? "") and \($0.substring)")
//                        }
//                        else {
//                            print("no delay \(diff)")//print("delay (\(diff)) between \(previousSegment) and \($0)")
//                        }
//                        previousTimestamp = $0.timestamp
//                        previousSegment = $0
//                    })
//                }
                
                self.transcription = result?.bestTranscription
                self.finishedTranscribing()
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)  //11
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()  //12
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        textView.text = "Say something, I'm listening!"
        
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            microphoneButton.isEnabled = true
        } else {
            microphoneButton.isEnabled = false
        }
    }
}

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

/*Enables you to throw a string*/
extension String: Error {}

/*Adds error.localizedDescription to Error instances*/
extension String: LocalizedError {
    public var errorDescription: String? { return self }
}

enum iTunesTrackIDs : String {
    case JonathanMyBride = "1212743725"
    case MJHumanNature = "269573405"
    case SealRose = "30475379"
    case WhitneyAlwaysLoveYou = "251101872"
    case WhitneyGreatestLove = "251101506"
    case LionelEndlessLove = "497012899"
    case LionelHello = "2872181"
    case StevieSoLovely = "549888978"
    case StevieJustCalled = "261716131"
    case BarryCantGetEnough = "3449401"
    case MinnieLovingYou = "1032485071"
    case BeattlesYesterday = "416565176"
    case LegendAllOfMe = "679297849"
    case Jackson5LovingYou = "46811"
    case Boyz2MenBendedKnee = "250038443"
    case All4OneISwear = "300974587"
    case ShaiIfIEverFallInLove = "60518"
    
    static let allValues: [iTunesTrackIDs] = [.JonathanMyBride, .MJHumanNature, .SealRose, .WhitneyAlwaysLoveYou, .WhitneyGreatestLove, .LionelEndlessLove, .LionelHello, .StevieSoLovely, .StevieJustCalled, .BarryCantGetEnough, .MinnieLovingYou, .BeattlesYesterday, .LegendAllOfMe, .Jackson5LovingYou, .Boyz2MenBendedKnee, .All4OneISwear, .ShaiIfIEverFallInLove]
    
    func trackShortName() -> String {
        switch self {
        case .JonathanMyBride:
            return "My Bride (Default)"
        case .MJHumanNature:
            return "Human Nature"
        case .SealRose:
            return "Kiss From A Rose"
        case .WhitneyAlwaysLoveYou:
            return "I Will Always Love You"
        case .WhitneyGreatestLove:
            return "Greatest Love of All"
        case .LionelEndlessLove:
            return "My Endless Love"
        case .LionelHello:
            return "Hello"
        case .StevieSoLovely:
            return "Isn't She Lovely"
        case .StevieJustCalled:
            return "Just Called To Say 'I Love You'"
        case .MinnieLovingYou:
            return "Loving You Is Easy"
        case .BarryCantGetEnough:
            return "Can't Get Enough Of Your Love"
        case .LegendAllOfMe:
            return "All Of Me"
        case .Jackson5LovingYou:
            return "Who's Loving You"
        case .BeattlesYesterday:
            return "Yesterday"
        case .Boyz2MenBendedKnee:
            return "Bended Knee"
        case .All4OneISwear:
            return "I Swear"
        case .ShaiIfIEverFallInLove:
            return "If I Ever Fall in Love"
        }
    }
}

// Now we should try recording the audio and playing it back with text
class SoundPlayer {
    var audioPlayer: AVAudioPlayer?
    var itunesResults: iTunesSearchResults?
    
    struct iTunesSearchResults : Codable {
        var resultCount: Int?
        var results: [iTunesSearchResultItem]?
        func trackPreviewURL() -> URL? {
            if let item = results?.first,
            let urlStr = item.previewUrl,
            let url = URL(string: urlStr) {
                return url
            }
            return nil
        }
        
        func trackDescription() -> String {
            if let item = results?.first,
                let artist = item.artistName,
                let track = item.trackName {
                return "\(track)\nby \(artist)"
            }
            return "Unknown"
        }
    }
    
    struct iTunesSearchResultItem : Codable {
        var previewUrl: String?
        var artistName: String?
        var trackName: String?
        var trackId: Int?
    }
    
    // song previews: https://affiliate.itunes.apple.com/resources/blog/song-previews/
    // sample url:  http://itunes.apple.com/us/lookup?id=823593456
    // BEST SINGLE EVER!!!!  https://itunes.apple.com/us/album/my-bride-wedding-song/1212743580?i=1212743725
    func playiTunesSongPreview(withId id: String = "1212743725", volume: Float = 0.2, completion: ((iTunesSearchResults?, Error?) -> Void)? = nil) {
        do {
            if let itunesResults = itunesResults, let url = itunesResults.trackPreviewURL() {
                playSound(withURL: url, volume: volume)
                completion?(itunesResults, nil)
                return
            }
            
            let jsonStr = try String(contentsOf: URL(string: "http://itunes.apple.com/us/lookup?id=\(id)")!)
            print("got json = \(jsonStr)")
            let data = jsonStr.data(using: .utf8)!
            let object = try JSONDecoder().decode(iTunesSearchResults.self, from: data)
            if let url = object.trackPreviewURL() {
                itunesResults = object
                print("playing track at url \(url)")
                playSound(withURL: url, volume: volume)
                completion?(itunesResults, nil)
            } else {
                throw "Cannot find track url"
            }
            
        } catch {
            print("error fetching details \(error.localizedDescription)")
            completion?(nil, error)
        }
    }
    
    func playSound(withName fileName: String, volume: Float = 0.25) {
        if let filePath: String = Bundle.main.path(forResource: fileName, ofType: "") {
            print("playing sound from path \(filePath)")
            playSound(withURL: URL(fileURLWithPath: filePath), volume: volume)
        }
    }
    
    func playSound(withURL fileURL: URL, volume: Float = 0.25) {
        do {
            if fileURL.isFileURL {
                let player = try AVAudioPlayer(contentsOf: fileURL)
                player.prepareToPlay()
                player.volume = volume
                player.play()
                player.numberOfLoops = -1
                audioPlayer = player
            }
            else {
                let data = try Data(contentsOf: fileURL)
                let player = try AVAudioPlayer(data: data)
                player.prepareToPlay()
                player.volume = volume
                player.play()
                player.numberOfLoops = -1
                audioPlayer = player
            }
            
        }
        catch {
            print("error playing file \(error.localizedDescription)")
        }
    }
    
    func stopSound() {
        audioPlayer?.stop()
    }
    
}

extension ViewController {
    func createFireworks() {
        fireworks.append(contentsOf: [Fireworks(), Fireworks()])
        fireworks.forEach({$0.createFireworks(in: view)})
    }
    
    func destroyFireworks() {
        fireworks.forEach({$0.destroyFireworks()})
        fireworks.removeAll()
    }
}

extension ViewController {
    //https://stackoverflow.com/questions/39238180/record-audio-with-added-effects
    //https://stackoverflow.com/questions/34537066/tap-installed-on-audio-engine-only-producing-short-files/34561042#34561042
//    func funAudioEngineStuff() {
//        func playAudio(pitch : Float, rate: Float, reverb: Float, echo: Float) {
//            // Initialize variables
//            audioEngine = AVAudioEngine()
//            audioPlayerNode = AVAudioPlayerNode()
//            audioEngine.attachNode(audioPlayerNode)
//
//            // Setting the pitch
//            let pitchEffect = AVAudioUnitTimePitch()
//            pitchEffect.pitch = pitch
//            audioEngine.attachNode(pitchEffect)
//
//            // Setting the platback-rate
//            let playbackRateEffect = AVAudioUnitVarispeed()
//            playbackRateEffect.rate = rate
//            audioEngine.attachNode(playbackRateEffect)
//
//            // Setting the reverb effect
//            let reverbEffect = AVAudioUnitReverb()
//            reverbEffect.loadFactoryPreset(AVAudioUnitReverbPreset.Cathedral)
//            reverbEffect.wetDryMix = reverb
//            audioEngine.attachNode(reverbEffect)
//
//            // Setting the echo effect on a specific interval
//            let echoEffect = AVAudioUnitDelay()
//            echoEffect.delayTime = NSTimeInterval(echo)
//            audioEngine.attachNode(echoEffect)
//
//            // Chain all these up, ending with the output
//            audioEngine.connect(audioPlayerNode, to: playbackRateEffect, format: nil)
//            audioEngine.connect(playbackRateEffect, to: pitchEffect, format: nil)
//            audioEngine.connect(pitchEffect, to: reverbEffect, format: nil)
//            audioEngine.connect(reverbEffect, to: echoEffect, format: nil)
//            audioEngine.connect(echoEffect, to: audioEngine.mainMixerNode, format: nil)
//
//
//            // Good practice to stop before starting
//            audioPlayerNode.stop()
//
//            // Play the audio file
//            if(audioEngine != nil){
//                audioEngine?.stop()
//            }
//
//            audioPlayerNode.scheduleFile(audioFile, atTime: nil, completionHandler: {
//                print("Complete")
//
//            })
//
//            try! audioEngine.start()
//
//
//            let dirPaths: AnyObject = NSSearchPathForDirectoriesInDomains( NSSearchPathDirectory.DocumentDirectory,  NSSearchPathDomainMask.UserDomainMask, true)[0]
//            let tmpFileUrl: NSURL = NSURL.fileURLWithPath(dirPaths.stringByAppendingPathComponent("dddeffefsdctedSoundf23f13.caf"))
//            filteredOutputURL = tmpFileUrl
//
//            do{
//                print(dirPaths)
//                print(tmpFileUrl)
//
//                self.newAudio = try! AVAudioFile(forWriting: tmpFileUrl, settings:[
//                    AVFormatIDKey: NSNumber(unsignedInt:kAudioFormatAppleLossless),
//                    AVEncoderAudioQualityKey : AVAudioQuality.Medium.rawValue,
//                    AVEncoderBitRateKey : 12800,
//                    AVNumberOfChannelsKey: 2,
//                    AVSampleRateKey : 44100.0
//                    ])
//
//                audioEngine.mainMixerNode.installTapOnBus(0, bufferSize: 2048, format: audioEngine.mainMixerNode.inputFormatForBus(0)) {
//                    (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
//
//                    print(self.newAudio.length)
//                    print("=====================")
//                    print(self.audioFile.length)
//                    print("**************************")
//                    if (self.newAudio.length) < (self.audioFile.length){//Let us know when to stop saving the file, otherwise saving infinitely
//
//                        do{
//                            //print(buffer)
//                            try self.newAudio.writeFromBuffer(buffer)
//                        }catch _{
//                            print("Problem Writing Buffer")
//                        }
//                    }else{
//                        self.audioEngine.mainMixerNode.removeTapOnBus(0)//if we dont remove it, will keep on tapping infinitely
//
//                    }
//
//                }
//            }catch _{
//                print("Problem")
//            }
//
//            audioPlayerNode.play()
//        }
}
