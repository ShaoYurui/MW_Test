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
class MwSensorVideoRecorderViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    
    let captureSession = AVCaptureSession()
    let mwDevices = AssessmentSettings.sharedManager.mwSensors
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var movieOutput: AVCaptureMovieFileOutput?
    var outputFileURL: URL?
    var recordButton:RecordButton!
    
    @IBOutlet var CameraView: UIView!
    @IBOutlet var recordButtonLabel: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mwDevices.fetchSavedMetawear{ type in
            self.mwDevices.startMetering(type: type)
        }
        
        startCameraPreview()
        
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
            StartRecording()
        }
        else {
            recordButton.buttonUntapped()
            recordButton.isRecording = false
            StopRecording()
            
            let storyboard = UIStoryboard(name: "MainStoryboard_iPad", bundle: nil)
            let nextViewController = storyboard.instantiateViewController(withIdentifier: "MwSensorSummaryViewController") as! MwSensorSummaryViewController
            self.present(nextViewController, animated: true, completion: nil)

        }
    }
    
    func StartRecording()
    {
        // start sensors
        mwDevices.startRecording()
        
        guard let movieOutput = self.movieOutput else { return }
        
        // set up dataTimeString for the output folder path and file name
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy_MM_dd_HHmm"
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
    
    func StopRecording()
    {
        // stop sensors
        mwDevices.stopRecording()
        mwDevices.stopMetering()
        
        guard let movieOutput = self.movieOutput else { return }
        
        // Stop recording
        movieOutput.stopRecording()
    }
    
      
}
