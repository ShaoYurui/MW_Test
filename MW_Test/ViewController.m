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
        [self->_mwDevices startMeteringWithType:type];
    });}];
    
}

- (IBAction)StartRecordingButton:(id)sender {
    [_mwDevices startRecording];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSTimer scheduledTimerWithTimeInterval:1.0
                                        repeats:YES
                                          block:^(NSTimer *timer){
            self.DataTextDisplay.text=[self.mwDevices getAccGyroMag];
        }];
    });
}

- (IBAction)StopRecordingButton:(id)sender {
    [_mwDevices stopRecording];
    [_mwDevices stopMetering];
}
@end
