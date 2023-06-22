//
//  VideoRecorderViewController.swift
//  MW_Test
//
//  Created by Rio Shao on 20/6/23.
//

import UIKit
import AVFoundation
import Photos

@objc
class MwSensorVideoRecorderViewController: UIViewController, AVCaptureFileOutputRecordingDelegate, GaitExerciseDelegate {
    
    let mwDevices = AssessmentSettings.sharedManager.mwSensors
    var gaitExercise:GaitExercise!
    
    let captureSession = AVCaptureSession()
    var movieOutput: AVCaptureMovieFileOutput?
    var outputFileURL: URL?
    var recordButton:RecordButton!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    var liveStackLabels = [String:UILabel]()
   
    
    @IBOutlet var CameraView: UIView!
    @IBOutlet var recordButtonLabel: UIButton!
    @IBOutlet var liveInfoStackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        gaitExercise = GaitExercise()
        gaitExercise.gaitExerciseDelegate = self
        
        mwDevices.fetchSavedMetawear{ type in
            self.mwDevices.startMetering(type: type)
        }
        
        startCameraPreview()
        liveInfoStackViewInit()
        
        recordButton = RecordButton()
        recordButtonLabel.layer.addSublayer(recordButton)
        recordButtonLabel.isHidden = false
        
    }
    
    
    // MARK: - AVCaptureFileOutputRecordingDelegate Methods
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        // Recording started
        print("Recording started.")
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        // Recording finished
        if let error = error {
            print("Error while recording: \(error.localizedDescription)")
            return
        }
    }
    
    // MARK: - End of AVCaptureFileOutputRecordingDelegate Methods

    func startCameraPreview()
    {
        // Check if the device has a camera and is capable of recording videos
        guard let videoDevice = AVCaptureDevice.default(for: .video),
              let audioDevice = AVCaptureDevice.default(for: .audio),
              let captureDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
              let audioDeviceInput = try? AVCaptureDeviceInput(device: audioDevice)
        else {
            print("Unable to access the camera or microphone.")
            return
        }
        
        // Add video input to the capture session
        if captureSession.canAddInput(captureDeviceInput) {
            captureSession.addInput(captureDeviceInput)
            captureSession.addInput(audioDeviceInput)
        } else {
            print("Unable to add video device input to the capture session.")
            return
        }
        
        // Add video output to the capture session
        movieOutput = AVCaptureMovieFileOutput()
        if captureSession.canAddOutput(movieOutput!) {
            captureSession.addOutput(movieOutput!)
        } else {
            print("Unable to add video output to the capture session.")
            return
        }
        
        // Configure video preview layer
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer?.frame = CameraView.bounds
        CameraView.layer.addSublayer(videoPreviewLayer!)
        
        // Start the capture session
        captureSession.startRunning()
    }
    
    @IBAction func recordButtonPressed(_ sender: Any) {
        if !recordButton.isRecording {
            recordButton.buttonTapped()
            recordButton.isRecording = true
            StartAssessment()
        }
        else {
            recordButton.buttonUntapped()
            recordButton.isRecording = false
            StopAssessment()
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let nextViewController = storyboard.instantiateViewController(withIdentifier: "MwSensorSummaryViewController") as! MwSensorSummaryViewController
            self.present(nextViewController, animated: true, completion: nil)

        }
    }
    
    func StartAssessment()
    {
        mwDevices.gaitExercise = self.gaitExercise
        mwDevices.startRecording()
        
        updateLiveInfo(keyData: ["Status:" : "Start"])
        
        guard let movieOutput = self.movieOutput else { return }
        
        // set up dataTimeString for the output folder path and file name
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy_MM_dd_HHmm_ss"
        AssessmentSettings.sharedManager.dateTimeString = dateFormatter.string(from: currentDate)
        
        // set up output file url
        let folderPath = AssessmentSettings.sharedManager.filesManager.documentsDirectory.path
        + String(format: "/MwSensor_%@/",        AssessmentSettings.sharedManager.dateTimeString)
        AssessmentSettings.sharedManager.filesManager.createFolder(path: folderPath)
        let fileURL = URL(fileURLWithPath: folderPath
                          + String(format: "video_%@.mov", AssessmentSettings.sharedManager.dateTimeString))
        outputFileURL = fileURL
        
        // Start recording to the file URL
        movieOutput.startRecording(to: fileURL, recordingDelegate: self)
    }
    
    func StopAssessment()
    {
        // stop sensors
        mwDevices.stopRecording()
        mwDevices.stopMetering()
        updateLiveInfo(keyData: ["Status:" : "End"])
        
        guard let movieOutput = self.movieOutput else { return }
        
        // Stop recording
        movieOutput.stopRecording()
    }
    
    /// set up liveStackView with labels according to AR setting
    func liveInfoStackViewInit()
    {
        liveInfoStackView.distribution = .fillEqually // Distributes labels evenly
        
        let gaitAssessmentWalk:[String] = ["Status:", "Duration:", "IMU Step count:", "IMU Stride times:", "IMU Cadence:", "IMU COV:"]
        // initialise once from gaitAssessmentWalk, subsequently hide/unhide 7th and above labels by toggleSwitchLabel
        if liveInfoStackView.subviews.isEmpty {
            gaitAssessmentWalk.forEach({assignLabelsToLiveStackView(title:$0)})
        }
        else {  // clear values
            for (key,label) in liveStackLabels {
                label.text = key
            }
        }
        
    }
    
    /// add label in liveInfoStackView
    /// - Parameter title: new label title
    func assignLabelsToLiveStackView(title:String)
    {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: liveInfoStackView.frame.width, height: 50))
        //print("liveInfoStackView label: \(label)")
        label.textAlignment = .left
        label.text = title
        if UIDevice.current.userInterfaceIdiom == .phone
        {
            label.font.withSize(3.0)
        }
        else {
            label.font.withSize(14.0)
        }
        label.textColor = .white
        label.numberOfLines = 10
        label.backgroundColor = .lightGray.withAlphaComponent(0.5)
        label.minimumScaleFactor = 0.7
    
        liveInfoStackView.addArrangedSubview(label)
        liveStackLabels[title] = label
    }
    
    /// delegate for GaitExercise to update live info with current exercise assessment
    /// - Parameter gaitResults: dictionary of exercise data in [String:Any] type
    func exerciseUpdate(gaitResults: [String : Any])
    {
        var results = [ "IMU Step count:" : String(format: "L: %d, R: %d", gaitResults["countLeftStep"] as! Int, gaitResults["countRightStep"] as! Int)]
        
        results ["Duration:"] = String(format: "%.2f sec", gaitResults["duration"] as! Float)
                                       
        if gaitResults["strideTimeValue"] as? Float != nil {
            results["IMU Stride times:"] = String(format: "Mean: %.2f\n Max: %.2f Min: %.2f s", gaitResults["strideTimeValue"] as! Float, gaitResults["maxStrideTime"] as! Float, gaitResults["minStrideTime"] as! Float)
            results["IMU Cadence:"] = String(format: "%.2f\n Max: %.2f Min: %.2f (steps/min)", gaitResults["rightCadence"] as! Float, gaitResults["maxCadence"] as! Float, gaitResults["minCadence"] as! Float)
            results["IMU COV:"] = String(format: "L: %.2f R: %.2f", gaitResults["leftCovOfvar"] as! Float, gaitResults["rightCovOfvar"] as! Float)
        }
        updateLiveInfo(keyData: results)
    }
    
    /// update live info with key data map
    /// - Parameter keyData: dictionary with label text as key for updating the data to liveInfoStackView
    func updateLiveInfo(keyData: [String: String]) {
        print(keyData)
        DispatchQueue.main.async
        {
            for (key, data) in keyData {
                if let label = self.liveStackLabels[key] {
                    label.text = "\(key) \(data)"
                }
            }
        }
        
    }
      
}
