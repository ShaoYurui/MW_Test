import UIKit

@objc
class MwSesnsorConnectionViewController: UIViewController {
    var timerCount: Int = 0
    
    @IBOutlet var LeftProgressBar: UIProgressView!
    @IBOutlet var RightProgressBar: UIProgressView!
    @IBOutlet var RightSensorConnectButton: UIButton!
    @IBOutlet var LeftSensorConnectButton: UIButton!
    @IBOutlet var ExitButton: UIButton!
    
    let mwDevices = AssessmentSettings.sharedManager.mwSensors
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        LeftProgressBar.progress = 0
        RightProgressBar.progress = 0
        
        connectSavedDevices()
    }
    
    func connectSavedDevices() {
        updateSensorConnectButtonFetching(type:.left)
        updateSensorConnectButtonFetching(type:.right)
        
        mwDevices.updateStatus()
        mwDevices.fetchSavedMetawear { [weak self] type in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.updateSensorConnectButtonConnected(type: type)
                self.mwDevices.readBatteryLevel()
                self.updateBatteryLevel()
            }
        }
    }
    
    func updateSensorConnectButtonFetching(type: MWSensor.SensorType) {
        let targetButton: UIButton
        switch type {
        case .left:
            targetButton = LeftSensorConnectButton
        case .right:
            targetButton = RightSensorConnectButton
        }
        targetButton.setTitleColor(.blue, for: .normal)
        targetButton.setTitle("Fetching", for: .normal)
        targetButton.isEnabled = true
    }
    
    func updateSensorConnectButtonConnect(type: MWSensor.SensorType) {
        let targetButton: UIButton
        switch type {
        case .left:
            targetButton = LeftSensorConnectButton
        case .right:
            targetButton = RightSensorConnectButton
        }
        targetButton.setTitleColor(.blue, for: .normal)
        targetButton.setTitle("Connect", for: .normal)
        targetButton.isEnabled = true
    }
    
    func updateSensorConnectButtonConnecting(type: MWSensor.SensorType) {
        let targetButton: UIButton
        switch type {
        case .left:
            targetButton = LeftSensorConnectButton
        case .right:
            targetButton = RightSensorConnectButton
        }
        targetButton.setTitleColor(.gray, for: .normal)
        targetButton.setTitle("Connecting", for: .normal)
        targetButton.isEnabled = false
    }
    
    func updateSensorConnectButtonConnected(type: MWSensor.SensorType) {
        let targetButton: UIButton
        switch type {
        case .left:
            targetButton = LeftSensorConnectButton
        case .right:
            targetButton = RightSensorConnectButton
        }
        targetButton.setTitleColor(.green, for: .normal)
        targetButton.setTitle("Connected", for: .normal)
        targetButton.isEnabled = true
    }
    
    func updateBatteryLevel() {
        DispatchQueue.main.async {
            Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] timer in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                
                let leftLevel = Float(self.mwDevices.getBatteryLevel(type: .left) ) / 100.0
                let rightLevel = Float(self.mwDevices.getBatteryLevel(type: .right) ) / 100.0
                
                self.LeftProgressBar.progress = leftLevel
                self.RightProgressBar.progress = rightLevel
                
                if leftLevel != 0 && rightLevel != 0 {
                    timer.invalidate()
                }
            }
        }
    }
    
    @IBAction func RightSensorConnectButtonPressed(_ sender: Any) {
        updateSensorConnectButtonConnecting(type:.right)
        pickUpSensor(type:.right)
    }
    
    @IBAction func LeftSensorConnectButtonPressed(_ sender: Any) {
        updateSensorConnectButtonConnecting(type:.left)
        pickUpSensor(type:.left)
    }
    
    @IBAction func ExitButtonPressed(_ sender: Any) {
        mwDevices.savePreferences()
    }
    
    func pickUpSensor(type: MWSensor.SensorType) {
        mwDevices.resetConnection(type: type)
        mwDevices.scanMetawear(type: type) { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.updateSensorConnectButtonConnected(type: type)
                self.mwDevices.readBatteryLevel()
                self.updateBatteryLevel()
            }
        }
        
        var counter = 10 // no of seconds to wait for scan
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            counter = counter - 1
            print("\(type.text) scan: \(counter)")
            if self.mwDevices.MWConnected[type] == true {
                DispatchQueue.main.async {
                    timer.invalidate()
                    self.mwDevices.stopScan()
                }
            }
            if self.mwDevices.MWConnected[type] == false || counter == 0
            {
                DispatchQueue.main.async {
                    self.updateSensorConnectButtonConnect(type:type)
                    timer.invalidate()
                    self.mwDevices.stopScan()
                }
            }
        }
    }
}
