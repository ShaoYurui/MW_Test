//
//  MwSesnsorConnectionViewController.m
//  MW_Test
//
//  Created by Rio Shao on 12/6/23.
//

#import "MwSesnsorConnectionViewController.h"

@interface MwSesnsorConnectionViewController ()

@end

@implementation MwSesnsorConnectionViewController

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _mwDevices = [[MWSensor alloc] init];
    _mwDevices = [_mwDevices getMwSensonrs];
    
    _LeftProgressBar.progress = 0;
    _RightProgressBar.progress = 0;
    
    [self ConnectSavedDevices];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}


- (void) ConnectSavedDevices
{
    [self UpdateSensorConnectButtonFetching: SensorTypeLeft];
    [self UpdateSensorConnectButtonFetching: SensorTypeRight];
    
    [_mwDevices fetchSavedMetawearWithCompletion:
     ^(SensorType type){dispatch_async(dispatch_get_main_queue(), ^{
        [self UpdateSensorConnectButtonConnected:type];
        [self->_mwDevices startMeteringWithType:type];
        [self->_mwDevices readBatteryLevel];
        [self UpdateBatteryLevel];
    });}];
}

- (void) UpdateSensorConnectButtonFetching: (SensorType) type
{
    UIButton *targetButton = [[UIButton alloc] init];
    if(type == SensorTypeLeft)
    {
        targetButton = _LeftSensorConnectButton;
    }
    else if(type == SensorTypeRight)
    {
        targetButton = _RightSensorConnectButton;
    }
    [targetButton setTitleColor:UIColor.blueColor forState:UIControlStateNormal];
    [targetButton setTitle:@"Fetching" forState:UIControlStateNormal];
    targetButton.enabled = YES;
}

- (void) UpdateSensorConnectButtonConnect: (SensorType) type
{
    UIButton *targetButton = [[UIButton alloc] init];
    if(type == SensorTypeLeft)
    {
        targetButton = _LeftSensorConnectButton;
    }
    else if(type == SensorTypeRight)
    {
        targetButton = _RightSensorConnectButton;
    }
    [targetButton setTitleColor:UIColor.blueColor forState:UIControlStateNormal];
    [targetButton setTitle:@"Connect" forState:UIControlStateNormal];
    targetButton.enabled = YES;
}

- (void) UpdateSensorConnectButtonConnecting: (SensorType) type
{
    UIButton *targetButton = [[UIButton alloc] init];
    if(type == SensorTypeLeft)
    {
        targetButton = _LeftSensorConnectButton;
    }
    else if(type == SensorTypeRight)
    {
        targetButton = _RightSensorConnectButton;
    }
    [targetButton setTitleColor:UIColor.grayColor forState:UIControlStateNormal];
    [targetButton setTitle:@"Connecting" forState:UIControlStateNormal];
    targetButton.enabled = NO;
}

- (void) UpdateSensorConnectButtonConnected: (SensorType) type
{
    UIButton *targetButton = [[UIButton alloc] init];
    if(type == SensorTypeLeft)
    {
        targetButton = _LeftSensorConnectButton;
    }
    else if(type == SensorTypeRight)
    {
        targetButton = _RightSensorConnectButton;
    }
    [targetButton setTitleColor:UIColor.greenColor forState:UIControlStateNormal];
    [targetButton setTitle:@"Connected" forState:UIControlStateNormal];
    targetButton.enabled = NO;
}


- (void) UpdateBatteryLevel
{
    // tries to read battery level from sensors for every 1 second,
    // until we sucessfully get the readings
    dispatch_async(dispatch_get_main_queue(), ^{
            [NSTimer scheduledTimerWithTimeInterval:0.2
                                            repeats:YES
                                              block:^(NSTimer *timer)
             {
                float leftLevel = (float)[self->_mwDevices getBatteryLevelWithType:SensorTypeLeft]/100.0;
                float rightLevel = (float)[self->_mwDevices getBatteryLevelWithType:SensorTypeRight]/100.0;
                
                self->_LeftProgressBar.progress = leftLevel;
                self->_RightProgressBar.progress = rightLevel;
                
                if(leftLevel != 0 && rightLevel != 0)
                {
                    [timer invalidate];
                }
            }];
        });
}

- (IBAction)RightSensorConnectButtonPressed:(id)sender {
    int type = SensorTypeRight;
    [self UpdateSensorConnectButtonConnecting:type];
    [self pickUpSensor:type];
}

- (IBAction)LeftSensorConnectButtonPressed:(id)sender {
    int type = SensorTypeLeft;
    [self UpdateSensorConnectButtonConnecting:type];
    [self pickUpSensor:type];
}

- (void) pickUpSensor: (SensorType) type
{
    [_mwDevices resetConnectionWithType:type];
    [_mwDevices scanMetawearWithType:type completion:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self UpdateSensorConnectButtonConnected:type];
            [self->_mwDevices startMeteringWithType:type];
            [self->_mwDevices readBatteryLevel];
            [self UpdateBatteryLevel];
        });
    }];
    
    timerCount = 10;
    [NSTimer scheduledTimerWithTimeInterval:1.0
                                    repeats:YES
                                      block:^(NSTimer *timer){
        self->timerCount = self->timerCount - 1;
        //printf("\(type.text) scan: \(counter)");
        if ([self->_mwDevices getMwConnectedWithType:type])
        {
            [self->_mwDevices stopScan];
            [timer invalidate];
        }
        else if (self->timerCount == 0)
        {
            [self->_mwDevices stopScan];
            [self UpdateSensorConnectButtonConnect:type];
            [timer invalidate];
        }
    }];
}

- (IBAction)ExitButtonPressed:(id)sender {
    [_mwDevices savePreferences];
}

@end
