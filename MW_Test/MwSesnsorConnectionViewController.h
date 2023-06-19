//
//  MwSesnsorConnectionViewController.h
//  MW_Test
//
//  Created by Rio Shao on 12/6/23.
//

#import <UIKit/UIKit.h>
#import "MW_Test-Swift.h"

@interface MwSesnsorConnectionViewController : UIViewController
{
    int timerCount;
}
@property (weak, nonatomic) IBOutlet UIProgressView *LeftProgressBar;
@property (weak, nonatomic) IBOutlet UIProgressView *RightProgressBar;
@property (weak, nonatomic) IBOutlet UIButton *RightSensorConnectButton;
@property (weak, nonatomic) IBOutlet UIButton *LeftSensorConnectButton;

@property (strong) MWSensor * mwDevices;

- (IBAction)LeftSensorConnectButtonPressed:(id)sender;
- (IBAction)RightSensorConnectButtonPressed:(id)sender;
- (IBAction)ExitButtonPressed:(id)sender;

@end
