//
//  ViewController.m
//  MW_Test
//
//  Created by Rio Shao on 1/6/23.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    self.LeftStatusTextDisplay.text = @"Left Status:\nNot Connected";
    self.RightStatusTextDisplay.text = @"Right Status:\nNot Connected";
    
    _mwDevices = [[MWSensor alloc] init];
    _mwDevices = [_mwDevices getMwSensonrs];
    
}

// Pressed connect button, start to connect two devices
- (IBAction)ConnectButton:(id)sender {
    self.LeftStatusTextDisplay.text = @"Left Status:\nConnecting...";
    self.RightStatusTextDisplay.text = @"Right Status:\nConnecting...";
    
    [_mwDevices fetchSavedMetawearWithCompletion:
     ^(SensorType type){dispatch_async(dispatch_get_main_queue(), ^{
        if(type == SensorTypeLeft)
        {
            self.LeftStatusTextDisplay.text = @"Left Status:\nConnected";
        }
        else if (type == SensorTypeRight)
        {
            self.RightStatusTextDisplay.text = @"Right Status:\nConnected";
        }
    });}];
}
/*
- (void) pickMetawearSensor: (SensorType) type
{
    
    [_mwDevices resetConnectionWithType:type];
    [_mwDevices scanMetawearWithType:type completion:
     ^{dispatch_async(dispatch_get_main_queue(), ^{
        if(type == SensorTypeLeft)
        {
            self.LeftStatusTextDisplay.text = @"Left Status:\n Connected";
        }
        else if (type == SensorTypeRight)
        {
            self.RightStatusTextDisplay.text = @"Right Status:\n Connected";
        }
    });}];
    
    int counter = 10;// no of seconds to wait for scan
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
}*/

@end
