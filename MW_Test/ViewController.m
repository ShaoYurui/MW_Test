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
    self.LeftStatusTextDisplay.text = @"Left Status:\n Not Connected";
    self.RightStatusTextDisplay.text = @"Right Status:\n Not Connected";
    _sis = [[MySwiftClass alloc] init];
    
    _mwDevices = [[MWSensor alloc] init];
    _mwDevices = [_mwDevices getMwSensonrs];
    
}

// Pressed connect button, start to connect two devices
- (IBAction)ConnectButton:(id)sender {

    [_sis printSome];
    
   // [_mwDevices fetchSavedMetawearWithCompletion:^(SensorType type){}];
    
//    [_mwDevices fetchSavedMetawearWithCompletion:^(SensorType type){
//        dispatch_async(dispatch_get_main_queue(), ^{printf("%ld", (long)type);});
//    }];
         
    [self pickMetawearSensor:SensorTypeLeft];
    //[self pickMetawearSensor(.left)]
    //[self pickMetawearSensor(.right)]
}

- (void) pickMetawearSensor: (SensorType) type
{
    [_mwDevices resetConnectionWithType:type];
    [_mwDevices scanMetawearWithType:type completion: ^void(){printf("%s",@"D");}];
     //   self.LeftStatusTextDisplay.text = @"Left Status: \n Connecting...";
     //   self.RightStatusTextDisplay.text = @"Right Status: \n Connecting...";}];//closure /lemda function
    /*
    
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
    }*/
}

@end
