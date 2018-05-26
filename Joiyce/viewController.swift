//
//  ViewController.swift
//  Joiyce
//
//  Created by Toon Van Strijp on 25/05/2018.
//  Copyright © 2018 Toon Van Strijp. All rights reserved.
//

import UIKit
import AVKit
import Lumina
import TextToSpeechV1
import ToneAnalyzerV3

class ViewController: LuminaViewController {
    var consecutiveDetectionCount = 0
    var previousResult: String = ""
    
    let textToSpeech = TextToSpeech(username: "1f56d614-7976-4a05-9dab-52e7599e710e", password: "x5YMVfBBMCbx")
    let toneAnalyzer = ToneAnalyzer(username: "6b9e70ab-dce6-4bfe-807b-ee685bc94fd9", password: "4ncXrD5KRMrR", version: "2018-05-26")
    
    var player: AVAudioPlayer?
    
    var speakBuffer: [String] = []
    
    var gameConfigObjects: [ObjectConfig]? {
        do {
            let objects = try GameConfig.load()
            return objects.sorted { $0.name < $1.name }
        } catch {
            return nil
        }
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.delegate = self
        self.streamingModelTypes = [SignLanguage_1303887258()]
        self.setShutterButton(visible: false)
        self.setTorchButton(visible: true)
        self.setCancelButton(visible: false)
        self.setSwitchButton(visible: false)
        LuminaViewController.loggingLevel = .info
        
        startTimer()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func speakPendingText(text: String){
        textToSpeech.synthesize(
            text: text,
            accept: "audio/wav",
            voice: "en-US_MichaelVoice",
            failure: { (error: Error) in print(error) }
            )
        {
            data in
            do {
                self.player = try AVAudioPlayer(data: data)
                self.player!.play()
            } catch {
                print("Failed to create audio player.")
            }
        }
    }
    
    func getTone(str: String) {
        let failure = { (error: Error) in print(error) }
        toneAnalyzer.tone(text: str, failure: failure) { tones in
            print(tones)
        }
    }
    
    func startTimer() {
        let timer = Timer.scheduledTimer(timeInterval: 3,
                             target: self,
                             selector: #selector(self.reset),
                             userInfo: nil,
                             repeats: false)
    }
    
    @objc func reset() {
        print("testo")
    }
}

extension ViewController: LuminaDelegate {
    func streamed(videoFrame: UIImage, with predictions: [LuminaRecognitionResult]?, from controller: LuminaViewController) {
        guard let bestName = predictions?.first?.predictions?.first?.name else {
            return
        }
        guard let bestConfidence = predictions?.first?.predictions?.first?.confidence else {
            return
        }
        if bestConfidence >= 0.8 {
            guard let gameConfigObjects = gameConfigObjects else {
                continueScanning()
                return
            }
            let filteredConfigObjects = gameConfigObjects.filter { $0.name == bestName }
            
            if(previousResult == bestName){
                return
            }
            
//            self.textPrompt = "Detecting: \(bestName) \(bestConfidence * 100)%"
            
            self.previousResult = bestName
            
            if(bestName == "speak"){
                return;
            }else{
                speakPendingText(text: (filteredConfigObjects.first?.getText())!)
                getTone(str: (filteredConfigObjects.first?.getText())!)
            }
        } else {
            continueScanning()
            //self.textPrompt = ""
        }
    }
    
    private func continueScanning() {
        self.consecutiveDetectionCount = 0
    }
}

extension ViewController {
    func objectDetected(label: String) {
        self.consecutiveDetectionCount = 0
        updateObjectUI(for: label)
    }
    
    func updateObjectUI(for label: String) {
//        textPrompt = "You found the \(label)!"
    }
}

