//
//  ViewController.h
//  MW_Test
//
//  Created by Rio Shao on 1/6/23.
//

#import <UIKit/UIKit.h>
#import "MW_Test-Swift.h"

@interface ViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextView *LeftStatusTextDisplay;
@property (weak, nonatomic) IBOutlet UITextView *RightStatusTextDisplay;
//@property (strong, nonatomic) NSTimer *timer;
@property (weak, nonatomic) IBOutlet UITextView *DataTextDisplay;
@property (weak, nonatomic) IBOutlet UIProgressView *LeftProgressBar;
@property (weak, nonatomic) IBOutlet UIProgressView *RightProgressBar;

@property (strong) MWSensor * mwDevices;

- (IBAction)StopRecordingButton:(id)sender;
- (IBAction)StartRecordingButton:(id)sender;
- (IBAction)ConnectButton:(id)sender;

@end

