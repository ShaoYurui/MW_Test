//
//  SettingsViewController.swift
//  AR_Gait
//
//  Created by Jiun Shiah Low on 22/3/23.
//

import UIKit

class SettingsViewController : UIViewController
{
   
    @IBOutlet weak var serverTextField: UITextField!
    @IBOutlet weak var biometricSwitch: UISwitch!
    @IBOutlet weak var apiTokenTextField: UITextField!
    @IBOutlet weak var pingLabel: UILabel!
    @IBOutlet weak var sensorTypeSwitch: UISwitch!
    @IBOutlet weak var leftLimbSensorButton: UIButton!
    @IBOutlet weak var rightLimbSensorButton: UIButton!
    
    let appDB = AppDatabase()
    let mwDevices = AssessmentSettings.sharedManager.mwSensors
    
//    override func loadView()
//    {
//        super.loadView()
//        appDB = AppDatabase()
//    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        serverTextField.text = AssessmentSettings.sharedManager.preferences![.webURL] as? String
        biometricSwitch.setOn(AssessmentSettings.sharedManager.preferences![.biometric] as! String == "Y", animated: true)
        apiTokenTextField.text = AssessmentSettings.sharedManager.preferences![.apiToken] as? String
        sensorTypeSwitch.setOn(AssessmentSettings.sharedManager.preferences![.useMetawear] as! String == "Y", animated: true)
        
        let sensorButtons:[MWSensor.SensorType:UIButton?] = [
            .left: self.leftLimbSensorButton,
            .right: self.rightLimbSensorButton
        ]
        leftLimbSensorButton.layer.backgroundColor = UIColor.systemGray2.cgColor
        rightLimbSensorButton.layer.backgroundColor = UIColor.systemGray2.cgColor
        mwDevices.fetchSavedMetawear { type in
            DispatchQueue.main.async {
                sensorButtons[type]??.layer.backgroundColor = UIColor.green.cgColor
            }
        }
    }
    
    @IBAction func updateServer(_ sender: UITextField)
    {
        if !sender.text!.isEmpty {
            AssessmentSettings.sharedManager.preferences![.webURL] = sender.text
        }
    }
    
    @IBAction func updateAPIToken(_ sender: UITextField)
    {
        if !sender.text!.isEmpty {
            AssessmentSettings.sharedManager.preferences![.apiToken] = sender.text
        }
    }
    
    @IBAction func exitSave(_ sender: UIButton)
    {
        mwDevices.savePreferences()
        appDB.savePreferences()
        appDB.saveAdminRecord()
        self.dismiss(animated: true)
    }
    
    @IBAction func exitWithoutSaving(_ sender: UIButton)
    {
        appDB.fetchPreferences()
        self.dismiss(animated: true)
    }
    
    @IBAction func toggleBiometric(_ sender: UISwitch)
    {
        if sender.isOn {
            AssessmentSettings.sharedManager.preferences![.biometric] = "Y"
            AssessmentSettings.sharedManager.appRecord![AppDatabase.kAdminUserName] = AssessmentSettings.sharedManager.administrator.name
//            print("\(String(describing: AssessmentSettings.sharedManager.administrator.adminUserName))")
        }
        else {
            AssessmentSettings.sharedManager.preferences![.biometric] = "N"
            AssessmentSettings.sharedManager.appRecord![AppDatabase.kAdminUserName] = "nil"
        }
    }
    
    @IBAction func pingTest(_ sender: UIButton)
    {
        // check for server connectivity
        pingLabel.text = "Pinging server..."
        sender.isEnabled = false
        self.view.endEditing(true)
        let api = WebAPI(timeout: 5)
        api.getData(urlStr: "/api/ping") {
            (jsonOutput, responseCode) in
            if responseCode > 200 {
                print("\(#function): response code is \(responseCode)")
                DispatchQueue.main.async {
                    self.pingLabel.text = "Server unreachable"
                    sender.isEnabled = true
                }
            }
            else {
                DispatchQueue.main.async {
                    self.pingLabel.text = "Server OK"
                    sender.isEnabled = true
                }
            }
        }
    }
    
    @IBAction func toggleSensorType(_ sender: UISwitch)
    {
        if sender.isOn {
            // use MetaWear
            AssessmentSettings.sharedManager.preferences[.useMetawear] = "Y"
            // reset IMU bluetooth
            Bluetooth.sharedManager.resetBluetooth()
        }
        else {
            // use HomeRehab IMU
            AssessmentSettings.sharedManager.preferences[.useMetawear] = "N"
        }
    }
    
    @IBAction func pickLeftSensor(_ sender: UIButton)
    {
        pickMetawearSensor(.left, button: sender)
    }
    
    @IBAction func pickRightSensor(_ sender: UIButton)
    {
        pickMetawearSensor(.right, button: sender)
    }
    
    func pickMetawearSensor(_ type: MWSensor.SensorType, button: UIButton)
    {
        // set button to gray and disabled while scanning begin
        DispatchQueue.main.async {
            button.layer.backgroundColor = UIColor.systemGray2.cgColor
            button.isEnabled = false
        }
        
        mwDevices.resetConnection(type: type)
        mwDevices.scanMetawear(type: type) {
            DispatchQueue.main.async {
                // change button color when connected successfully
                button.layer.backgroundColor = UIColor.green.cgColor
            }
        }
        
        var counter = 10 // no of seconds to wait for scan
        messageAlertHelper(title: "Scan", message: "Scanning for \(type.text) Metawear sensor. If not found after \(counter) seconds, please retry")

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            counter = counter - 1
            print("\(type.text) scan: \(counter)")
            if self.mwDevices.MWConnected[type] == true || counter == 0 {
                DispatchQueue.main.async {
                    button.isEnabled = true
                }
                timer.invalidate()
                self.mwDevices.stopScan()
            }
        }
    }
    
    func messageAlertHelper(title: String, message: String)
    {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.view.tintColor = .primaryColor
        
        let okAction = UIAlertAction(title: "OK!", style: UIAlertAction.Style.default) {
           UIAlertAction in
           print("ok Pressed")
        }
        
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
}
