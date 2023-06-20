//
//  MwSensorSummaryViewController.h
//  MW_Test
//
//  Created by Rio Shao on 19/6/23.
//

#import <UIKit/UIKit.h>
#import "MW_Test-Swift.h"
#import <WebKit/WebKit.h>

@interface MwSensorSummaryViewController : UIViewController 

@property (strong) MWSensor * mwDevices;

@property (weak, nonatomic) IBOutlet WKWebView *csvSummary;
@property (strong) NSURLRequest *filePathUrlRequest;

@end
