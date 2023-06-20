//
//  AssessmentSettings.swift
//  AR Gait SPPB
//
//  Created by Jerome Derrick on 3/7/21.
//

import Foundation
import MetaWear

// Global variables
@objc
class AssessmentSettings : NSObject
{
    static var sharedManager = AssessmentSettings()
    
    var assessmentType: String!
    // var participant:Participant!
    // var administrator:Administrator!
    
    var appRecord : [String: Any]!
    var participantDemo : [String: [String: Any]]!
    
    enum PreferenceKeys {
        case webURL, biometric, apiToken, useMetawear, leftSensor, rightSensor
    }
    var preferences : [PreferenceKeys: Any]! = [:]
    //[.leftSensor:"2A3A73D5-E782-468C-45F3-08FB846F7404" ,
    // .rightSensor:"662191AB-877B-7B0F-AC54-84303C2250FB"]
    
    
    // for file upload
    // let uploader = Uploader()
    
    // for push notification
    var deviceToken: String = ""
    
    // for Metawear sensors
    let mwSensors = MWSensor()
    
    @objc
    func getMwSensors() -> MWSensor
    {
        return self.mwSensors
    }
}

