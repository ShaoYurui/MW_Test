//
//  GaitExercise.swift
//  GaitExercise
//
//  Created by Jerome Derrick on 11/8/21.
//

import UIKit

protocol GaitExerciseDelegate:AnyObject
{
    func exerciseUpdate(gaitResults:[String:Any])
}


class GaitExercise
{

    let ALPHA:Float = 0.9
    var STEP_THRESHOLD:Float = 10000
    
    // instance variables for each side of limb
    let LEFT = 0
    let RIGHT = 1
    var prevMaxTime:[Float] = [0, 0]
    var prevGyroFiltered:[Float] = [0, 0]
    var goAbvThres:[Bool] = [false, false]
    var deadCounter:[Int] = [0, 0]
    var countStep:[Int] = [0, 0]
    var maxFilValue:[Float] = [0, 0]
    var currentMaxTime:[Float] = [0, 0]
    var isFindingMax:[Bool] = [false, false]
    var legStartTime:[Float] = [0, 0]
    var totalStrideTime:[Float] = [0, 0]
    var totalStrideTimeSq:[Float] = [0, 0]
    var meanStrideTime:[Float] = [0, 0]
    var covOfvar:[Float] = [0, 0]
    var cadence:[Float] = [0, 0]
    var currentTime = 0
    
    var prevLeftMaxTime:Float = 0
    var prevRightMaxTime:Float = 0
    
    var prevLeftGyroFiltered:Float = 0
    var leftGoAbvThres = false
    var leftDeadCounter = 0
    var countLeftStep = 0
    var maxLeftFilValue:Float = 0
    var currentLeftMaxTime:Float = 0
    var isFindingLeftmax = false
    var leftLegStartTime:Float = 0
    var totalLeftStrideTime:Float = 0
    var totalLeftStrideTimeSq:Float = 0
//    var meanLeftStrideTime:Float = 0
//    var sdLeftStrideTime:Float = 0
    var leftCovOfvar:Float = 0
    
    var prevRightGyroFiltered:Float = 0
    var rightGoAbvThres = false
    var rightDeadCounter = 0
    var countRightStep = 0
    var maxRightFilValue:Float = 0
    var currentRightMaxTime:Float = 0
    var isFindingRightmax = false
    var rightLegStartTime:Float = 0
    var totalRightStrideTime:Float = 0
    var totalRightStrideTimeSq:Float = 0
//    var meanRightStrideTime:Float = 0
//    var sdRightStrideTime:Float = 0
    var rightCovOfvar:Float = 0
    var rightCadence:Float = 0
    
    var maxStrideTime:Float = 0
    var minStrideTime:Float = 100000
    var maxCadence:Float = 0
    var minCadence:Float = 100000
    
    var totalStepCount = 0
    var prevTotalStepCount = 0
    
    var gaitResults:[String:Any] = [String:Any]()
    
    weak var gaitExerciseDelegate:GaitExerciseDelegate?
    
    
    func doLegAnalysis(side:Int, ay:Float, gz:Float, time: Int)
    {
        gaitResults["duration"] = Float(time)/1000
        let gyroZ_value : Float
        if STEP_THRESHOLD == 1000000 { // HomeRehab IMU, no change to original logic
            gyroZ_value = max(gz,0)
        }
        else {
            // GyroZ value has mirror-like pattern between left and right
            // because device front is facing out from leg, thus Z-axis is opposite direction for left and right
            // right has a cleaner positive TO peaks while left has u-shaped peaks (HS, Terminal double support)
            // For Metawear, perhaps flip left, ignore negative parts and count step based on TO event
            gyroZ_value = side == LEFT ? max(-gz,0) : max(gz,0)
        }
        
        let gyroFiltred = (prevGyroFiltered[side] * ALPHA) + (gyroZ_value * (1 - ALPHA))
        prevGyroFiltered[side] = gyroFiltred
        let gyroFiltredSq = gyroFiltred * gyroFiltred
        
        if gyroFiltredSq > STEP_THRESHOLD && !goAbvThres[side] && deadCounter[side] == 0 && ay < 100000 {
            countStep[side] += 1
            deadCounter[side] += 1
            goAbvThres[side] = true
        }
        else if gyroFiltredSq < STEP_THRESHOLD && goAbvThres[side] {
            goAbvThres[side] = false
            maxFilValue[side] = 0
        }
        
//        if gyroFiltredSq > STEP_THRESHOLD && goAbvThres[side] {
        if goAbvThres[side] {
            if abs(gyroZ_value) > maxFilValue[side] {
                maxFilValue[side] = gyroZ_value
                currentMaxTime[side] = roundf(Float(time)/1000*100)/100
            }
            isFindingMax[side] = true
        }
        
//        if gyroFiltredSq < STEP_THRESHOLD && isFindingMax[side] {
        if !goAbvThres[side] && isFindingMax[side] {
            isFindingMax[side] = false
            
            if countStep[side] == 1 {
                legStartTime[side] = currentMaxTime[side]
            }
            else if countStep[side] > 1
            {
                //print("currentMaxTime[\(side)]: \(currentMaxTime[side])")
                let strideTime = currentMaxTime[side] - prevMaxTime[side]
                totalStrideTime[side] += strideTime
                totalStrideTimeSq[side] += strideTime * strideTime //pow(rightStrideTime, 2)
                meanStrideTime[side] = totalStrideTime[side] / Float(countStep[side] - 1)
                
                //Calculate to the current mean
                let meanStrideTime = totalStrideTime[side] / Float(countStep[side])
                
                //Calculate to the current SD
                let sdRightStrideTime = (totalStrideTimeSq[side] / Float(countStep[side])) - (meanStrideTime*meanStrideTime)
                covOfvar[side] = sdRightStrideTime / meanStrideTime
    
                cadence[side] = (Float(countStep[side] - 1) / (currentMaxTime[side] - legStartTime[side]))*60*2
                // only use cadence for right side
                if side == RIGHT {
                    minStrideTime = min(strideTime, minStrideTime)
                    maxStrideTime = max(strideTime, maxStrideTime)
                    minCadence = min(cadence[side], minCadence)
                    maxCadence = max(cadence[side], maxCadence)
                }
            }
            prevMaxTime[side] = currentMaxTime[side]
        }
        
        if deadCounter[side] > 0 {
            deadCounter[side] += 1
            if deadCounter[side] > 50 {
                deadCounter[side] = 0
            }
        }
        
        totalStepCount = countStep[LEFT] + countStep[RIGHT]
        if totalStepCount != prevTotalStepCount {
            //delegate results
            updateGaitAnalysis()
        }
        prevTotalStepCount = totalStepCount
        //print("countLeftStep: \(countStep[LEFT]), countRightStep: \(countStep[RIGHT]), totalStepCount: \(totalStepCount)")
    }
    
    func updateGaitAnalysis()
    {
        gaitResults["countLeftStep"] = countStep[LEFT]
        gaitResults["countRightStep"] = countStep[RIGHT]
       
        // Only shows stride times, cadence and cov when Right stride time has value
        if meanStrideTime[RIGHT] > 0 {
            gaitResults["strideTimeValue"] = meanStrideTime[RIGHT]
            
            gaitResults["maxStrideTime"] = maxStrideTime
            gaitResults["minStrideTime"] = minStrideTime
            

            gaitResults["rightCadence"] = cadence[RIGHT]
            gaitResults["maxCadence"] = maxCadence
            gaitResults["minCadence"] = minCadence
            
            gaitResults["leftCovOfvar"] = covOfvar[LEFT]
            gaitResults["rightCovOfvar"] = covOfvar[RIGHT]
        }
        
    }
}

