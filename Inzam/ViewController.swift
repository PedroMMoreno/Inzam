//
//  ViewController.swift
//  ML Sound Classifier
//
//  Created by Pedro Moreno on 05/08/2021.
//

import UIKit
import AVKit
import AVFoundation
import SoundAnalysis

//Test coment

class ViewController: UIViewController , AVAudioPlayerDelegate , AVAudioRecorderDelegate {
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    
    private let audioEngine = AVAudioEngine()
    private var soundClassifier = try! MySoundClassifier_1(configuration: MLModelConfiguration.init())
    
    var inputFormat: AVAudioFormat!
    var analyzer: SNAudioFileAnalyzer!
    var resultsObserver = ResultsObserver()
    let analysisQueue = DispatchQueue(label: "com.custom.AnalysisQueue")
    
    
    @IBOutlet weak var recordButton: UIButton!
    var isRecording = false
    
    @IBOutlet weak var playButton: UIButton!
    var isPlaying = false
    
    var soundRecorder : AVAudioRecorder!
    var soundPlayer : AVAudioPlayer!
    
    var fileName: String = "audioFile.m4a"
    
    @IBOutlet weak var instrumentDisplay: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        spinner.isHidden = true
        setupRecorder()
        playButton.isEnabled = false
        
        resultsObserver.delegate = self
        inputFormat = audioEngine.inputNode.inputFormat(forBus: 0)
        
        //analyzer = SNAudioStreamAnalyzer(format: inputFormat) -> For real-time prediction
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //startAudioEngine() -> For real-time prediction
        buildUI()
    }
    
    let transcribedText:UILabel = {
        let view = UILabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .center
        view.textAlignment = .center
        view.numberOfLines = 0
        view.font = UIFont.systemFont(ofSize: 20)
        view.tag = 10
        return view
    }()
    
    
    func buildUI()    {
        self.view.addSubview(transcribedText)
        
        NSLayoutConstraint.activate(
            [transcribedText.centerYAnchor.constraint(equalTo: view.centerYAnchor),
             transcribedText.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
             transcribedText.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
             transcribedText.heightAnchor.constraint(equalToConstant: 100),
             transcribedText.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ]
        )
        
    }
    
    
    
    func setUpUIRecord(x: Int, y: Int) {
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 140, weight: .bold, scale: .large)
        let largeRecBold = UIImage(systemName: "record.circle.fill", withConfiguration: largeConfig)
        
        recordButton.setImage(largeRecBold, for: .normal)
        recordButton.frame = CGRect(x: x, y: y, width: 80, height: 80)
    }
    
    func setUpUIPlay(x: Int, y: Int) {
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 140, weight: .bold, scale: .large)
        let largeRecBold = UIImage(systemName: "play.circle.fill", withConfiguration: largeConfig)
        
        playButton.setImage(largeRecBold, for: .normal)
        playButton.frame = CGRect(x: x, y: y, width: 80, height: 80)
    }
    
    func setUpUIStop(button: UIButton, x: Int, y: Int) {
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 140, weight: .bold, scale: .large)
        let largeRecBold = UIImage(systemName: "stop.circle.fill", withConfiguration: largeConfig)
        
        button.setImage(largeRecBold, for: .normal)
        button.frame = CGRect(x: x, y: y, width: 80, height: 80)
    }
    
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    
    func setupRecorder() {
        
        let audioFilename = getDocumentsDirectory().appendingPathComponent(fileName)
        let recordSetting = [ AVFormatIDKey : kAudioFormatAppleLossless,
                              AVEncoderAudioQualityKey : AVAudioQuality.max.rawValue,
                              AVEncoderBitRateKey : 440000,
                              AVNumberOfChannelsKey : 1,
                              AVSampleRateKey : 44100.2] as [String : Any]
        
        do {
            soundRecorder = try AVAudioRecorder(url: audioFilename, settings: recordSetting )
            soundRecorder.delegate = self
            soundRecorder.prepareToRecord()
        } catch {
            print(error)
        }
    }
    
    func setupPlayer() {
        
        
        let audioFilename = getDocumentsDirectory().appendingPathComponent(fileName)
        do {
            soundPlayer = try AVAudioPlayer(contentsOf: audioFilename)
            soundPlayer.delegate = self
            soundPlayer.prepareToPlay()
            soundPlayer.volume = 1.0
            let settings = soundPlayer.settings.description
            print(settings)
        } catch {
            print(error)
        }
    }
    
    
    @IBAction func recordAct(_ sender: Any) {
        if let foundView = view.viewWithTag(10) {
            foundView.isHidden = true
        }
        if isRecording == false {
            
            instrumentDisplay.loadGif(name: "recording")
            
            soundRecorder.record()
            recordButton.setImage(UIImage(named: "stop_1.png"), for: .normal)
            
            playButton.isEnabled = false
            isRecording = true
        } else {
            recordButton.setImage(UIImage(named: "rec.png"), for: .normal)
            
            soundRecorder.stop()
            playButton.isEnabled = true
            isRecording = false
            instrumentDisplay.image = UIImage(named: "ear")
        }
    }
    
    @IBAction func playAct(_ sender: Any) {
        if let foundView = view.viewWithTag(10) {
            foundView.isHidden = true
        }
        if isPlaying == false {
            instrumentDisplay.loadGif(name: "sound")
            
            recordButton.isEnabled = false
            setupPlayer()
            soundPlayer.play()
            playButton.setImage(UIImage(named: "stop_2.png"), for: .normal)
            
            isPlaying = true
            
        } else {
            
            soundPlayer.stop()
            
            recordButton.isEnabled = true
            isPlaying = false
            playButton.setImage(UIImage(named: "play.png"), for: .normal)
            instrumentDisplay.image = UIImage(named: "ear")
        }
    }
    
    
    @IBAction func animateSpinner(_ sender: Any) {   instrumentDisplay.isHidden = true
        spinner.isHidden = false
        spinner.hidesWhenStopped = true
        spinner.startAnimating()
    }
    
    @IBAction func predictResults(_ sender: UIButton) {
        recordButton.isEnabled = false
        playButton.isEnabled = false
        
        
        do {
            
            
            analyzer = try SNAudioFileAnalyzer(url: getDocumentsDirectory().appendingPathComponent(fileName))
            
        } catch {
            print("Error with the recorded audio.")
        }
        do{
            let request = try SNClassifySoundRequest(mlModel: soundClassifier.model)
            try analyzer.add(request, withObserver: resultsObserver)
        } catch {
            print("Unable to prepare request: \(error.localizedDescription)")
            return
        }
        analyzer.analyze()
    }
    
    /* For real time prediction:
     private func startAudioEngine() {
     do {
     let request = try SNClassifySoundRequest(mlModel: soundClassifier.model)
     try analyzer.add(request, withObserver: resultsObserver)
     } catch {
     print("Unable to prepare request: \(error.localizedDescription)")
     return
     }
     
     audioEngine.inputNode.installTap(onBus: 0, bufferSize: 8000, format: inputFormat) { buffer, time in
     self.analysisQueue.async {
     self.analyzer.analyze(buffer, atAudioFramePosition: time.sampleTime)
     }
     }
     
     do{
     try audioEngine.start()
     }catch( _){
     print("error in starting the Audio Engin")
     }
     }*/
    
    let instrumentClasses: [String: String] = ["voi":"Human Singing", "gel": "Electric Guitar", "pia": "Piano", "org": "Organ", "gac": "Acoustic Guitar", "sax":"Saxophone", "vio": "Violin", "tru":"Trumpet", "cla":"Clarinet", "flu":"Flute", "cel": "Cello"]
    
    func displayImage(instrument: String){
        spinner.stopAnimating()
        instrumentDisplay.isHidden = false
        instrumentDisplay.image = UIImage(named: instrument)
        recordButton.isEnabled = true
        playButton.isEnabled = true
    }
}
protocol InstrumentClassifierDelegate {
    func displayPredictionResult(identifier: String, confidence: Double)
}

extension ViewController: InstrumentClassifierDelegate {
    
    
    func displayPredictionResult(identifier: String, confidence: Double) {
        DispatchQueue.main.async {
            let formattedConfidence = String(format: "%.2f", confidence)
            
            let instrument = self.instrumentClasses[identifier]!
            self.transcribedText.isHidden = false
            self.transcribedText.text = ("Recognition: \(instrument) \nConfidence \(formattedConfidence) %")
            self.displayImage(instrument: identifier)
        }
    }
    func displayInstrument(){
        
    }
}



class ResultsObserver: NSObject, SNResultsObserving {
    var delegate: InstrumentClassifierDelegate?
    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let result = result as? SNClassificationResult,
              let classification = result.classifications.first else { return }
        
        let confidence = classification.confidence * 100.0
        
        if confidence > 60 {
            delegate?.displayPredictionResult(identifier: classification.identifier, confidence: confidence)
        }
    }
}


