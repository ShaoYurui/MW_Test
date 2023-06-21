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
@property (weak, nonatomic) IBOutlet UITextView *DataTextDisplay;
@property (weak, nonatomic) IBOutlet UIProgressView *LeftProgressBar;
@property (weak, nonatomic) IBOutlet UIProgressView *RightProgressBar;

- (IBAction)ConnectButtonPressed:(id)sender;


@property (strong) MWSensor * mwDevices;



@end

