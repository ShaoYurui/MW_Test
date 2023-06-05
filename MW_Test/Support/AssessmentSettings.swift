//
//  AssessmentSettings.swift
//  AR Gait SPPB
//
//  Created by Jerome Derrick on 3/7/21.
//

import Foundation
import MetaWear

// Global variables

struct AssessmentSettings
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
    var preferences : [PreferenceKeys: Any]!
    
    // for file upload
    // let uploader = Uploader()
    
    // for push notification
    var deviceToken: String = ""
    
    // for Metawear sensors
    let mwSensors = MWSensor()
    
}

