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
import ReplayKit


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
    
    // Magic !!!
    var fireworks: [Fireworks] = []
    var music: SoundPlayer = SoundPlayer()
    var selectedTrackId = iTunesTrackIDs.JonathanMyBride
    @IBOutlet var creditsLabel: UILabel!

    // Replay Kit
    let recorder = RPScreenRecorder.shared()
    private var isRecordingScreen = false

    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resetButton.isHidden = true
        scrollView.isHidden = true
        creditsLabel.isHidden = true
        
        synthesizer = AVSpeechSynthesizer()
        synthesizer?.delegate = self
        
        setupSpeechRecognizer()
        let _ = recorder.isAvailable 
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
        
        let audioSession = AVAudioSession.sharedInstance()  //2
        do {
            try audioSession.setCategory(AVAudioSessionCategoryAmbient, with: AVAudioSessionCategoryOptions.defaultToSpeaker)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        
        if recorder.isAvailable {
            recorder.startRecording { [unowned self] (error) in
                
                guard error == nil else {
                    print("There was an error starting the recording.")
                    return
                }
                
                print("Started Recording Screen Successfully")
                self.isRecordingScreen = true
            }
        }
        
        if let segments = transcription?.segments, segments.count > 0 {
            
            var previousTimestamp : TimeInterval = 0
            var previousSegment: SFTranscriptionSegment? = nil
            var phrases: [Phrase] = []
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
        creditsLabel.isHidden = true

        destroyFireworks()
        music.stopSound()
        stopRecording()
    }
    
    @IBAction func recordButtonTapped() {
        stopRecording()
        //let's reset too
        resetButtonTapped(resetButton)
    }
    
    // MARK: - Private methods

    func newLabelWithText(text: String) -> UILabel {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 30, weight: UIFont.Weight.thin )
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
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: AVAudioSessionCategoryOptions.defaultToSpeaker)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()  //3
        let inputNode = audioEngine.inputNode
         //4
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        } //5
        
        recognitionRequest.shouldReportPartialResults = true  //6
        var date = Date()
        var delays: [TimeInterval] = [];
        var words = [String]()
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in  //7
            
            var isFinal = false  //8
            
            if result != nil {
                
                let delay = Date().timeIntervalSince(date)
                date = Date()
//                print("delay = \(delay), isFinal = \(String(describing: result?.isFinal))")
                delays.append(delay)
                if let word = result?.bestTranscription.segments.last?.substring, (words.last == nil || word != words.last) {
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
                
//                print("segment times = \((result?.bestTranscription.segments as? NSArray)?.value(forKey: "timestamp"))")
                
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

extension ViewController : RPPreviewViewControllerDelegate {
    func stopRecording() {
        
        recorder.stopRecording { [unowned self] (preview, error) in
            print("Stopped recording")
            
            guard preview != nil else {
                print("Preview controller is not available.")
                return
            }
            
            let alert = UIAlertController(title: "Recording Finished", message: "Would you like to edit or delete your recording?", preferredStyle: .alert)
            
            let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: { (action: UIAlertAction) in
                self.recorder.discardRecording(handler: { () -> Void in
                    print("Recording suffessfully deleted.")
                })
            })
            
            let editAction = UIAlertAction(title: "Edit", style: .default, handler: { (action: UIAlertAction) -> Void in
                preview?.previewControllerDelegate = self
                self.present(preview!, animated: true, completion: nil)
            })
            
            alert.addAction(editAction)
            alert.addAction(deleteAction)
            self.present(alert, animated: true, completion: nil)
            
            self.isRecordingScreen = false
        }
        
    }
    
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        dismiss(animated: true)
    }
}
