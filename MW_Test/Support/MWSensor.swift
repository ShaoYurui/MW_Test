//
//  MWSensor.swift
//  AR_Gait
//
//  Created by Jiun Shiah Low on 19/4/23.
//

import Foundation
import MetaWear
import MetaWearCpp

@objc
class MWSensor : NSObject
{
    @objc
    enum SensorType : Int, CaseIterable {
        case left, right
        var text: String {
            return String(describing: self)
        }
        var ledColor: MblMwLedColor {
            switch self {
            case .left: return MBL_MW_LED_COLOR_GREEN
            case .right: return MBL_MW_LED_COLOR_BLUE
            }
        }
    }
    
    @objc
    enum DataType : Int, CaseIterable {
        case time,ax,ay,az,gx,gy,gz,mx,my,mz
        var text: String {
            return String(describing: self)
        }
    }
    
    enum MeterType: CaseIterable {
        case accelerometer, gyroscope, magnetometer
        var text: String {
            return String(describing: self)
        }
    }
    
    var sensor:[SensorType:MetaWear] = [:]
    var peripheralID:[SensorType:String] = [:]
    var MWConnected: [SensorType:Bool] = [:]
    
    // data collections
    struct TXYZ {
        var time:Int  // time in millisecond
        var x:Float
        var y:Float
        var z:Float
    }
    var startTime:Date = Date()
    var accelerometer:[SensorType:[TXYZ]] = [.left:[], .right:[]]
    var gyroscope:[SensorType:[TXYZ]] = [.left:[], .right:[]]
    var magnetometer:[SensorType:[TXYZ]] = [.left:[], .right:[]]
    var streamingCleanup:[OpaquePointer:()->()] = [:]
    var isRecording:Bool = false
    
    // merged data set
    struct AGM {
        var ax,ay,az:Float!
        var gx,gy,gz:Float!
        var mx,my,mz:Float!
    }
    struct TAGM {
        var time:Int!  // time in millisecond
        var ax,ay,az:Float!
        var gx,gy,gz:Float!
        var mx,my,mz:Float!
    }
    var accGyroMagRaw:[SensorType:[TAGM]] = [.left:[], .right:[]]
    var accGyroMag:[SensorType:[TAGM]] = [.left:[], .right:[]]
    
    // bridging data for C closure required for Metawear API to refer to self instance
    class BridgeData {
        var type:SensorType
        var mwSensor: MWSensor
        init(type: SensorType, mwSensor: MWSensor) {
            self.type = type
            self.mwSensor = mwSensor
        }
    }
    lazy var bdPacks:[SensorType:BridgeData] = [
        .left: BridgeData(type: .left, mwSensor: self),
        .right: BridgeData(type: .right, mwSensor: self)
    ]
    
    // GaitExercise update
    // weak var gaitExercise:GaitExercise?
    
    @objc
    func getMwSensonrs()-> MWSensor
    {
        print("runing getMwSensonrs")
        return AssessmentSettings.sharedManager.mwSensors;
    }
    
    /*
     {
     left  : [{ax:1,ay:2...},{},{}...]
     right : [{},{},{}...]
     }
     */
    @objc
    func getAccGyroMagString()-> String
    {
        return accGyroMag.description
    }
    
    @objc
    func getAccGyroMag()-> [[[Any]]]
    {
        var array = [[[Any]]]()
        for type in MWSensor.SensorType.allCases
        {
            let list = accGyroMag[type]
            var array_for_type = [[Any]]()
            for elementTAGM in list!
            {
                var array_for_TAGM = [Any]()
                array_for_TAGM.append(elementTAGM.time)
                array_for_TAGM.append(elementTAGM.ax)
                array_for_TAGM.append(elementTAGM.ay)
                array_for_TAGM.append(elementTAGM.az)
                array_for_TAGM.append(elementTAGM.gx)
                array_for_TAGM.append(elementTAGM.gy)
                array_for_TAGM.append(elementTAGM.gz)
                array_for_TAGM.append(elementTAGM.mx)
                array_for_TAGM.append(elementTAGM.my)
                array_for_TAGM.append(elementTAGM.mz)
                
                array_for_type.append(array_for_TAGM)
            }
            array.append(array_for_type)
        }
        
        return array
        
    }
    
    
    /// Fetch saved Metawear devices
    /// - Parameter completion: closure to run after succesful connection
    @objc
    func fetchSavedMetawear(completion: @escaping (SensorType)->Void )
    {
        let savedSensorID:[SensorType:String?] = [
            .left: AssessmentSettings.sharedManager.preferences[.leftSensor] as? String,
            .right: AssessmentSettings.sharedManager.preferences[.rightSensor] as? String
        ]
        print("Saved devices are: \(String(describing: savedSensorID[.left])) \(String(describing: savedSensorID[.right]))")
        // check if already connected
        for (type, id) in savedSensorID {
            if peripheralID[type] != nil && peripheralID[type] == id && MWConnected[type]! {
                completion(type)
            }
        }
        // go through each saved device
        if !savedSensorID.isEmpty {
            MetaWearScanner.shared.retrieveSavedMetaWearsAsync().continueOnSuccessWith { [weak self] deviceList in
                for device in deviceList {
                    let peripheralID = device.peripheral.identifier.uuidString
                    if let type = savedSensorID.first(where: {$0.value == peripheralID})?.key {
                        if self?.MWConnected[type] != true {  // attempt to connect if not connected
                            self?.connectMetawear(device: device, ledColor: type.ledColor) {
                                self?.MWConnected[type] = true
                                self?.sensor[type] = device
                                self?.peripheralID[type] = peripheralID
                                print("Connected to saved \(type.text) device \(String(describing: savedSensorID[type]!))")
                                completion(type)
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Scan for Metawear devices
    /// - Parameter completion: closure to run after succesful connection
    func scanMetawear(type: SensorType, completion: @escaping ()->Void )
    {
        MetaWearScanner.shared.startScan(allowDuplicates: true) { [weak self] device in
            // We found a MetaWear board, see if it is close
            print("Found a \(device.name) device: RSSI = \(device.rssi)")
            if device.rssi > -50 {
               // Hooray! We found a MetaWear board, so stop scanning for more
               MetaWearScanner.shared.stopScan()
               // Connect to the board we found
                self?.connectMetawear(device: device, ledColor: type.ledColor) {
                    // set connection state
                    self?.MWConnected[type] = true
                    self?.sensor[type] = device
                    self?.peripheralID[type] = device.peripheral.identifier.uuidString
                    device.remember()
                    completion()
                }
            }
        }
    }
    
    /// Connect to a Metawear device
    /// - Parameter device: Metawear instance
    /// - Parameter completion: closure to run upon successful connection
    func connectMetawear(device: MetaWear, ledColor: MblMwLedColor, completion: @escaping ()->Void )
    {
        device.connectAndSetup().continueWith { t in
            if let error = t.error {
                // Sorry we couldn't connect
                print("Connect to device failed: \(error)")
            }
            else {
                print("Connected to device \(String(describing: device.mac)) \(device.peripheral.identifier.uuidString)")
                
                device.apiAccessQueue.async {
                    // blink LED to identify sensor
                    var pattern = MblMwLedPattern()
                    mbl_mw_led_load_preset_pattern(&pattern, MBL_MW_LED_PRESET_PULSE)
                    mbl_mw_led_stop_and_clear(device.board)
                    mbl_mw_led_write_pattern(device.board, &pattern, ledColor)
                    mbl_mw_led_play(device.board)
                }
                
                let seconds = 8.0
                device.apiAccessQueue.asyncAfter(deadline: .now() + seconds) {
                    mbl_mw_led_stop_and_clear(device.board)
                }
                completion()
            }
        }
    }
    
    /// reset connection for Metawear device
    func resetConnection(type: SensorType)
    {
        if MWConnected[type] == true {
            sensor[type]?.cancelConnection()
            sensor[type]?.forget()
        }
        MWConnected[type] = nil
        sensor[type] = nil
        peripheralID[type] = nil
    }
    
    /// Stop scanning for devices
    func stopScan()
    {
        MetaWearScanner.shared.stopScan()
    }
    
    /// get current state of devices
    func updateStatus()
    {
        for (type,device) in sensor {
            MWConnected[type] = device.isConnectedAndSetup
        }
    }
    
    /// Save current state into AssessmentSettings preference keys
    func savePreferences()
    {
        if let sensor = sensor[.left] {
            AssessmentSettings.sharedManager.preferences[.leftSensor] = sensor.peripheral.identifier.uuidString
            print("Saved left device: \(sensor.peripheral.identifier.uuidString)")
        }
        else {
            AssessmentSettings.sharedManager.preferences[.leftSensor] = ""
        }
        
        if let sensor = sensor[.right] {
            AssessmentSettings.sharedManager.preferences[.rightSensor] = sensor.peripheral.identifier.uuidString
            print("Saved right device: \(sensor.peripheral.identifier.uuidString)")
        }
        else {
            AssessmentSettings.sharedManager.preferences[.rightSensor] = ""
        }
    }
    
    func startAccelerator(type: SensorType)
    {
        if let device = sensor[type] {
//        }
//        for (type,device) in sensor {
            // configure accelerometer streaming
//            print("startAccelerator: \(type.text) \(String(describing: device.mac))")
            device.apiAccessQueue.async {
                mbl_mw_acc_bosch_set_range(device.board, MBL_MW_ACC_BOSCH_RANGE_4G)
                mbl_mw_acc_set_odr(device.board, 50)
                mbl_mw_acc_bosch_write_acceleration_config(device.board)
                // subscribe to data signal
                let signal = mbl_mw_acc_bosch_get_acceleration_data_signal(device.board)!
                mbl_mw_datasignal_subscribe(signal, bridge(obj: self.bdPacks[type]!)) { (context, obj) in
                    let acceleration: MblMwCartesianFloat = obj!.pointee.valueAs()
                    let dataPackIn : BridgeData = bridge(ptr: context!)
                    dataPackIn.mwSensor.addMeterData(dataPackIn.type, .accelerometer, time: obj!.pointee.timestamp, record: acceleration)
                    
                }
                // start streaming data signal
                mbl_mw_acc_enable_acceleration_sampling(device.board)
                mbl_mw_acc_start(device.board)
                
                self.streamingCleanup[signal] = {
                    mbl_mw_acc_stop(device.board)
                    mbl_mw_acc_disable_acceleration_sampling(device.board)
                    mbl_mw_datasignal_unsubscribe(signal)
                }
            }
        }
    }
    
    func startGyroscope(type: SensorType)
    {
        if let device = sensor[type] {
//        for (type,device) in sensor {
            // configure gyroscope streaming
//            print("startGyroscope: \(type.text) \(String(describing: device.mac))")
            device.apiAccessQueue.async {
                mbl_mw_gyro_bmi160_set_range(device.board, MBL_MW_GYRO_BOSCH_RANGE_2000dps)
                mbl_mw_gyro_bmi160_set_odr(device.board, MBL_MW_GYRO_BOSCH_ODR_50Hz)
                mbl_mw_gyro_bmi160_write_config(device.board)
                // subscribe to data signal
                let signal = mbl_mw_gyro_bmi160_get_rotation_data_signal(device.board)!
                
                mbl_mw_datasignal_subscribe(signal, bridge(obj: self.bdPacks[type]!)) { (context, obj) in
                    let gyroscope: MblMwCartesianFloat = obj!.pointee.valueAs()
                    let dataPackIn : BridgeData = bridge(ptr: context!)
                    dataPackIn.mwSensor.addMeterData(dataPackIn.type, .gyroscope, time: obj!.pointee.timestamp, record: gyroscope)
                }
                mbl_mw_gyro_bmi160_enable_rotation_sampling(device.board)
                mbl_mw_gyro_bmi160_start(device.board)
                
                self.streamingCleanup[signal] = {
                    mbl_mw_gyro_bmi160_stop(device.board)
                    mbl_mw_gyro_bmi160_disable_rotation_sampling(device.board)
                    mbl_mw_datasignal_unsubscribe(signal)
                }
            }
        }
    }
    
    func startMagnetometer(type: SensorType)
    {
        if let device = sensor[type] {
//        for (type,device) in sensor {
            // configure magnetometer streaming
//            print("startMagnetometer: \(type.text) \(String(describing: device.mac))")
            device.apiAccessQueue.async {
                mbl_mw_mag_bmm150_configure(device.board, 7, 7, MBL_MW_MAG_BMM150_ODR_30Hz)
                // subscribe to data signal
                let signal = mbl_mw_mag_bmm150_get_b_field_data_signal(device.board)!
                
                mbl_mw_datasignal_subscribe(signal, bridge(obj: self.bdPacks[type]!)) { (context, obj) in
                    let magnetometer: MblMwCartesianFloat = obj!.pointee.valueAs()
                    let dataPackIn : BridgeData = bridge(ptr: context!)
                    dataPackIn.mwSensor.addMeterData(dataPackIn.type, .magnetometer, time: obj!.pointee.timestamp, record: magnetometer)
                }
                mbl_mw_mag_bmm150_enable_b_field_sampling(device.board)
                mbl_mw_mag_bmm150_start(device.board)
                
                self.streamingCleanup[signal] = {
                    mbl_mw_mag_bmm150_stop(device.board)
                    mbl_mw_mag_bmm150_disable_b_field_sampling(device.board)
                    mbl_mw_datasignal_unsubscribe(signal)
                }
            }
        }
    }
    
    /// Start meters in MetaWear sensor
    @objc
    func startMetering(type: SensorType)
    {
        startAccelerator(type: type)
        startGyroscope(type: type)
        startMagnetometer(type: type)
        print("MWDevice \(type.text) meter started")
    }
    
    /// Stop meters in MetaWear sensor
    @objc
    func stopMetering()
    {
        while !streamingCleanup.isEmpty {
            streamingCleanup.popFirst()?.value()
        }
        print("MWDevice meter stopped")
    }
    
    /// Reset clock and meter data array, then start data collection
    @objc
    func startRecording()
    {
        accelerometer = [.left:[], .right:[]]
        gyroscope = [.left:[], .right:[]]
        magnetometer = [.left:[], .right:[]]
        startTime = Date()
        isRecording = true
    }
    
    /// Stop data collection and merge data
    @objc
    func stopRecording()
    {
        isRecording = false
        mergeData()
        //print(accGyroMag)
    }
    
    /// When is recording, collect data through data signal subscription and append to corresponding meter data array
    /// - Parameter type: side of limb sensor (left, right)
    /// - Parameter meter: meter type (accelerometer, gyroscope, magnetometer
    /// - Parameter time: timestamp from sensor
    /// - Parameter record: 3-axis data from sensor
    func addMeterData(_ type: SensorType, _ meter: MeterType, time: Date, record: MblMwCartesianFloat)
    {
//        print("\(type.text) \(meter.text) \(record)")
        if isRecording {
            var newRecord = TXYZ(time: Int(time.timeIntervalSince(startTime)*1000), x: record.x, y: record.y, z: record.z)
            //        newRecord.time = Int(newRecord.time/20) * 20  // round up to next 20ms time mark
            switch meter {
            case .accelerometer:
                // output data in mm/s^2 unit, input is g
                newRecord.x *= 9810 // *9.81m/s^2 * 1000mm/m
                newRecord.y *= 9810
                newRecord.z *= 9810
                accelerometer[type]?.append(newRecord)
            case .gyroscope:
                // output data in degree/sec, input is the same
                gyroscope[type]?.append(newRecord)
                // update gaitExercise if exists and accelerometer data not empty
//                if !accelerometer[type]!.isEmpty {
//                    gaitExercise?.doLegAnalysis(side: type.rawValue, ay: accelerometer[type]!.last!.y, gz: newRecord.z, time: newRecord.time)
//                }
            case .magnetometer:
                // output data in milli Gauss, input is micro Tesla
                newRecord.x *= 10 // *1/10^6 T/uT * 10^4 G/T * 10^3 mG/G
                newRecord.y *= 10
                newRecord.z *= 10
                magnetometer[type]?.append(newRecord)
            }
            //        print("\(type.text) \(meter.text) \(newRecord)")
        }
    }
    
    /// Merge data of accelerometer, gyroscope, magnetometer by time
    /// Update into instance variable:
    /// accGyroMagRaw :  actual sensor data merged in a sparse matrix with nil as missing value
    /// accGyroMag: interpolated sensor data merged in a 50-Hz or 20ms interval matrix without missing value
    func mergeData() {
//        accGyroMag[.left] = accelerometer[.left]! + gyroscope[.left]! + magnetometer[.left]!
        var buf:[Int:AGM]
        for type in SensorType.allCases {
            if accelerometer[type]!.isEmpty || gyroscope[type]!.isEmpty || magnetometer[type]!.isEmpty {
                print("WARNING: Not enough data to merge on \(type.text) side")
                print("Accelerometer data count: \(accelerometer[type]!.count)")
                print("Gyroscope data count: \(gyroscope[type]!.count)")
                print("Magnetometer data count: \(magnetometer[type]!.count)")
                return
            }
            buf = [:]
            accelerometer[type]?.forEach{ rec in
                if buf[rec.time] != nil {
                    buf[rec.time]?.ax = rec.x
                    buf[rec.time]?.ay = rec.y
                    buf[rec.time]?.az = rec.z
                }
                else {
                    buf[rec.time] = AGM(ax:rec.x, ay:rec.y, az:rec.z)
                }
            }
            gyroscope[type]?.forEach{ rec in
                if buf[rec.time] != nil {
                    buf[rec.time]?.gx = rec.x
                    buf[rec.time]?.gy = rec.y
                    buf[rec.time]?.gz = rec.z
                }
                else {
                    buf[rec.time] = AGM(gx:rec.x, gy:rec.y, gz:rec.z)
                }
            }
            magnetometer[type]?.forEach{ rec in
                if buf[rec.time] != nil {
                    buf[rec.time]?.mx = rec.x
                    buf[rec.time]?.my = rec.y
                    buf[rec.time]?.mz = rec.z
                }
                else {
                    buf[rec.time] = AGM(mx:rec.x, my:rec.y, mz:rec.z)
                }
            }
            // order by time
            let timeSequence = Array(buf.keys).sorted()
            accGyroMagRaw[type] = []
            for t in timeSequence {
                accGyroMagRaw[type]?.append(TAGM(time: t,
                                                 ax: buf[t]?.ax, ay: buf[t]?.ay, az: buf[t]?.az,
                                                 gx: buf[t]?.gx, gy: buf[t]?.gy, gz: buf[t]?.gz,
                                                 mx: buf[t]?.mx, my: buf[t]?.my, mz: buf[t]?.mz))
            }
        }
        // generate a uniform ranged data, starts from time when all 3 readings are present across both sides
        // align to 50Hz (every 20ms)
        var rangeBegin:Int = max(accelerometer[.left]!.first?.time ?? 0,
                             gyroscope[.left]!.first?.time ?? 0,
                             magnetometer[.left]!.first?.time ?? 0,
                             accelerometer[.right]!.first?.time ?? 0,
                             gyroscope[.right]!.first?.time ?? 0,
                             magnetometer[.right]!.first?.time ?? 0)
        rangeBegin = (((rangeBegin - 1) / 20) + 1 ) * 20
        var rangeEnd:Int = min(accelerometer[.left]!.last?.time ?? Int.max,
                           gyroscope[.left]!.last?.time ?? Int.max,
                           magnetometer[.left]!.last?.time ?? Int.max,
                           accelerometer[.right]!.last?.time ?? Int.max,
                           gyroscope[.right]!.last?.time ?? Int.max,
                           magnetometer[.right]!.last?.time ?? Int.max)
        rangeEnd = (rangeEnd / 20) * 20
        
        for type in SensorType.allCases {
            var (ai, gi, mi) = (0, 0, 0)
            var axyz, gxyz, mxyz : TXYZ?
            accGyroMag[type] = []
            for t in stride(from: rangeBegin, through: rangeEnd, by: 20) {
                (ai, axyz) = interpolateXYZArr(arr: accelerometer[type]!, initial_index: ai, time: t)
                (gi, gxyz) = interpolateXYZArr(arr: gyroscope[type]!, initial_index: gi, time: t)
                (mi, mxyz) = interpolateXYZArr(arr: magnetometer[type]!, initial_index: mi, time: t)
                accGyroMag[type]?.append(TAGM(time: t,
                                               ax: axyz?.x, ay: axyz?.y, az: axyz?.z,
                                               gx: gxyz?.x, gy: gxyz?.y, gz: gxyz?.z,
                                               mx: mxyz?.x, my: mxyz?.y, mz: mxyz?.z))
            }
            
        }
    }
    
    /// Linear interpolate of x to get y based on (x1,y1) and (x2,y2) where x1 < x2
    func interpolate(x1: Int, y1: Float, x2: Int, y2: Float, x: Int) -> Float
    {
        (y2-y1)/Float(x2-x1)*Float(x-x1) + y1
    }
    
    /// Linear interpolate of t -> (x,y,z) based on a pair of known t -> (x,y,z)
    ///  If input t is not within the interval, return nil
    func interpolateXYZ(d1: TXYZ, d2: TXYZ, time: Int) -> TXYZ?
    {
        if d1.time == time {  // exactly on interval boundary
            return d1
        }
        if d1.time < time && time < d2.time {  // within interval, interpolate
            return TXYZ(time: time,
                        x: interpolate(x1: d1.time, y1: d1.x, x2: d2.time, y2: d2.x, x: time),
                        y: interpolate(x1: d1.time, y1: d1.y, x2: d2.time, y2: d2.y, x: time),
                        z: interpolate(x1: d1.time, y1: d1.z, x2: d2.time, y2: d2.z, x: time))
        }
        return nil
    }
    
    /// Linrear interpolate of t -> (x,y,z) based on an array of t -> (x,y,z)  and search from initial index
    /// Assume array is sorted by ascending time
    /// - returns: tuple of final index and (x,y,z).  Nil for (x,y,z) if beyond the range of whole array
    func interpolateXYZArr(arr:[TXYZ], initial_index: Int, time: Int) -> (Int, TXYZ?)
    {
        var i = initial_index
        var xyz = interpolateXYZ(d1: arr[i], d2: arr[i+1], time: time)
        while xyz == nil && i < arr.count - 2 {
            i += 1
            xyz = interpolateXYZ(d1: arr[i], d2: arr[i+1], time: time)
        }
        return (i, xyz)
    }
}
