//
//  CSVWriter.swift
//  AR Gait SPPB
//
//  Created by Jerome Derrick on 1/7/21.
//
import GLKit

@objc
class CsvWriter : NSObject
{
    var filesManager:FilesManager
    var fileHandler:FileHandle!
    var convTimeOffsetBool:Bool
    var convTimeOffsetFloat:Float
    var initFileHandler1:Bool
    
    override init()
    {
        filesManager = FilesManager()
        convTimeOffsetBool = true
        convTimeOffsetFloat = 0
        initFileHandler1 = false
    }
    
    /// write IMU summary into CSV
    ///  - parameter assessmentDict: final gait exercise results
    ///  - parameter filePath: folder name
    ///  - parameter fileName: file name
    public func writeAssessmentSummary(assessmentDict:[String:Any], filePath:String, fileName:String) -> URL
    {
        let folderName = filesManager.documentsDirectory.path + "/" + filePath;
        filesManager.createFolder(path: folderName)
        
        let pathName = String(format: "%@/%@", folderName, fileName)
        if filesManager.createFile(atPath: pathName, contents: nil, attributes: nil) {
            let fileHandler = FileHandle(forWritingAtPath: pathName)
            print("writeAssessmentSummary file:\(pathName)")
            let headerString = "Parameters, value\n"
            fileHandler?.write(Data(headerString.utf8))
            
            let totalStepCount = (assessmentDict["countLeftStep"] as? Int ?? 0) + (assessmentDict["countRightStep"] as? Int ?? 0)
            
            var writeString = String(format: "%@ sec,%.2f\n", "Duration", assessmentDict["duration"] as? Float ?? "0")
            writeString += String(format: "%@,%d\n", "Left step count", assessmentDict["countLeftStep"] as? Int ?? "0")
            writeString += String(format: "%@,%d\n", "Right step count", assessmentDict["countRightStep"] as? Int ?? "0")
            writeString += String(format: "%@,%d\n", "Step count", totalStepCount)
            writeString += String(format: "%@,%.2f\n", "Stride times (Mean)", assessmentDict["strideTimeValue"] as? Float ?? "0")
            writeString += String(format: "%@,%.2f\n", "Stride times (Max)", assessmentDict["maxStrideTime"] as? Float ?? "0")
            writeString += String(format: "%@,%.2f\n", "Stride times (Max)", assessmentDict["minStrideTime"] as? Float ?? "0")
            writeString += String(format: "%@,%.2f\n", "Cadence (steps/min)", assessmentDict["rightCadence"] as? Float ?? "0")
            writeString += String(format: "%@,%.2f\n", "Max cadence (steps/min)", assessmentDict["maxCadence"] as? Float ?? "0")
            writeString += String(format: "%@,%.2f\n", "Min cadence (steps/min)", assessmentDict["minCadence"] as? Float ?? "0")
            writeString += String(format: "%@,%.2f\n", "Coefficient of variation (Left)", assessmentDict["leftCovOfvar"] as? Float ?? "0")
            writeString += String(format: "%@,%.2f", "Coefficient of variation (Right)", assessmentDict["rightCovOfvar"] as? Float ?? "0")
            
            print("assessmentSummary writeString: \(writeString)")
            fileHandler?.write(Data(writeString.utf8))
        }
        let fileUrl = URL(fileURLWithPath: pathName)
        return fileUrl
    }

    /// write Metawear sensor  data into CSV
    ///  - parameter mwSensor: instance of metawear sensor
    ///  - parameter type: left or right
    ///  - parameter filePath: folder name
    ///  - parameter fileName: file name
    @objc
    public func writeMetawear(mwSensor: MWSensor, type: MWSensor.SensorType, filePath:String, fileName:String)
    {
        let folderName = filesManager.documentsDirectory.path + "/" + filePath;
        filesManager.createFolder(path: folderName)
        let pathName = String(format: "%@/%@", folderName, fileName)
        if filesManager.createFile(atPath: pathName, contents: nil, attributes: nil) {
            let fileHandler = FileHandle(forWritingAtPath: pathName)
            
            let headerString = "sensor_time,gyro[0],gyro[1],gyro[2],acc[0],acc[1],acc[2],mag[0],mag[1],mag[2]\n"
            fileHandler?.write(Data(headerString.utf8))
            
            for rec in mwSensor.accGyroMag[type]! {
                let sensorTimeFloat = Float(rec.time) * 0.001
                let writeString = String(format: "%.3f,%@,%@,%@,%@,%@,%@,%@,%@,%@\n", sensorTimeFloat,
                                         FtoStr(rec.gx), FtoStr(rec.gy), FtoStr(rec.gz),
                                         FtoStr(rec.ax), FtoStr(rec.ay), FtoStr(rec.az),
                                         FtoStr(rec.mx), FtoStr(rec.my), FtoStr(rec.mz))
                fileHandler?.write(Data(writeString.utf8))

            }
            //print("done file \(pathName)")
        }
        
        //let fileUrl = URL(fileURLWithPath: pathName)
        //return fileUrl
    }
    
    func FtoStr(_ optNum: Float?) -> String
    {
        optNum != nil ? String(format: "%.2f", optNum!) : ""
    }
}
