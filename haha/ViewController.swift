//
//  ViewController.swift
//  haha
//
//  Created by 余忻妍 on 10/19/19.
//  Copyright © 2019 velocity. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController , SFSpeechRecognizerDelegate{

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))  //1
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    @IBOutlet weak var microphoneButton: UIButton!
    
    @IBOutlet weak var textView: UITextView!
    
//    @IBOutlet weak var textView: UITextView!
//    @IBOutlet weak var microphoneButton: UIButton!
    
    override func viewDidLoad() {
        // Do any additional setup after loading the view.
        super.viewDidLoad()
        
        microphoneButton.isEnabled = false  //2
        // Configure the SFSpeechRecognizer object already
        // stored in a local member variable.
        speechRecognizer?.delegate = self  //3
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in  //4
            
            var isButtonEnabled = false
            
            switch authStatus {  //5
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
            @unknown default:
                print("something doesn't know")
            }
            
            OperationQueue.main.addOperation() {
                self.microphoneButton.isEnabled = isButtonEnabled
            }
        }
    }
    
    
    func startRecording() {
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.record)
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true, options:.notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
//        let inputNode = audioEngine.inputNode else {
//            fatalError("Audio engine has no input node")
//        }
        let inputNode = audioEngine.inputNode //skeptical about how to fix this
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        recognitionRequest.shouldReportPartialResults = true
        
        // save the previous result
        let previousOutput = self.textView.text == "This is a text view" ? "" : self.textView.text
        
        recognitionTask = speechRecognizer!.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            /* note
                problem 1: the original method outputs the sentence to the console multiple times (temp-fix, hasSuffix)
                
             */
            if result != nil {
                self.textView.text = previousOutput! + " " + (result?.bestTranscription.formattedString)!
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.microphoneButton.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        if textView.text == "This is a text view" {
            textView.text = "Say something, I'm listening!"
        }
        
        
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            microphoneButton.isEnabled = true
        } else {
            microphoneButton.isEnabled = false
        }
    }
    
    
    
     @IBAction func microphoneTapped(_ sender: AnyObject) {
         if audioEngine.isRunning {
             audioEngine.stop()
             recognitionRequest?.endAudio()
             microphoneButton.isEnabled = false
             microphoneButton.setTitle("Hold To Start Recording", for: .normal)
         }
     }
     

     @IBAction func buttonDown(_ sender: Any) {
         startRecording()
         microphoneButton.isEnabled = false
         microphoneButton.setTitle("Release To Stop Recording", for: .normal)
     }
     

}

