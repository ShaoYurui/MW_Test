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
    
    _LeftProgressBar.progress = 0;
    _RightProgressBar.progress = 0;
    
    [self FetchDevices];
}

- (void) OpenMwSensorConnectionView
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    MwSesnsorConnectionViewController *nextViewController = [storyboard instantiateViewControllerWithIdentifier:@"MwSesnsorConnectionViewController"];
    [self presentViewController:nextViewController animated:YES completion:nil];

}

- (void) FetchDevices
{
    self.LeftStatusTextDisplay.text = @"Left Status:\nConnecting...";
    self.RightStatusTextDisplay.text = @"Right Status:\nConnecting...";

    [_mwDevices fetchSavedMetawearWithCompletion:
     ^(SensorType type){dispatch_async(dispatch_get_main_queue(), ^{
        if(type == SensorTypeLeft)
        {
            self.LeftStatusTextDisplay.text = @"Left Status:\nConnected";
            //[self->_mwDevices startMeteringWithType:SensorTypeLeft];
        }
        else if (type == SensorTypeRight)
        {
            self.RightStatusTextDisplay.text = @"Right Status:\nConnected";
            //[self->_mwDevices startMeteringWithType:SensorTypeRight];
        }
        [self->_mwDevices readBatteryLevel];
        [self UpdateBatteryLevel];
    });}];
}


- (void) UpdateBatteryLevel
{
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

- (NSString *) GetStringData: (NSArray *)list
{
    NSString *result = @"";
    for(int i = 0; i < list.count; i++)
    {
        result = [NSString stringWithFormat: @"%@~~~~~~~~~~~~~%@~~~~~~~~~~~~~\n%@  %@  %@\n%@  %@  %@\n%@  %@  %@\n\n", result,
                  list[i][DataTypeTime],
                  list[i][DataTypeAx],
                  list[i][DataTypeAy],
                  list[i][DataTypeAz],
                  list[i][DataTypeGx],
                  list[i][DataTypeGy],
                  list[i][DataTypeGz],
                  list[i][DataTypeMx],
                  list[i][DataTypeMy],
                  list[i][DataTypeMz]];
    }
    return result;
}



- (IBAction)ConnectButtonPressed:(id)sender {
    [self OpenMwSensorConnectionView];
}

@end
