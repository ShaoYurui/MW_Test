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
@property (strong, nonatomic) NSTimer *timer;
@property (weak, nonatomic) IBOutlet UITextView *DataTextDisplay;


@property (strong) MWSensor * mwDevices;
@property (strong) MySwiftClass * sis;

- (IBAction)StopRecordingButton:(id)sender;
- (IBAction)StartRecordingButton:(id)sender;
- (IBAction)ConnectButton:(id)sender;


@end

