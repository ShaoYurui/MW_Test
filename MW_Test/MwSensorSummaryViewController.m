//
//  MwSensorSummaryViewController.m
//  MW_Test
//
//  Created by Rio Shao on 19/6/23.
//

#import "MwSensorSummaryViewController.h"

@interface MwSensorSummaryViewController ()

@end

@implementation MwSensorSummaryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // initialise and get MwSensors
    _mwDevices = [[MWSensor alloc] init];
    _mwDevices = [_mwDevices getMwSensonrs];
    
    NSDate *currentDate = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy_MM_dd_HHmm"];
    NSString *dateTimeString = [dateFormatter stringFromDate:currentDate];
    
    // write MwSensor Data into Csv Files
    NSURL *fileUrl = [_mwDevices writeAssessmentToFileWithFilePath:[NSString stringWithFormat:@"MwSensor_%@", dateTimeString]
                                                fileName:[NSString stringWithFormat:@"MwSensor_Summary_%@.csv", dateTimeString]];
    
    [_mwDevices writeDataToFileWithFilePath:[NSString stringWithFormat:@"MwSensor_%@", dateTimeString]
                                   fileName:[NSString stringWithFormat:@"MwSensor_Right_%@.csv", dateTimeString]
                                       type:SensorTypeRight];
    
    [_mwDevices writeDataToFileWithFilePath:[NSString stringWithFormat:@"MwSensor_%@", dateTimeString]
                                   fileName:[NSString stringWithFormat:@"MwSensor_Left_%@.csv", dateTimeString]
                                       type:SensorTypeLeft];
    
    // display CSV files into WebView
    NSMutableString *htmlContent = [self convertCsvToHtmlContent:fileUrl];
    [_csvSummary loadHTMLString:htmlContent baseURL:nil];
}

- (NSMutableString *)convertCsvToHtmlContent:(NSURL *)fileUrl {
    NSString *csvFilePath = [fileUrl path];
    NSString *csvContent = [NSString stringWithContentsOfFile:csvFilePath encoding:NSUTF8StringEncoding error:nil];

    NSMutableString *htmlContent = [NSMutableString string];
    [htmlContent appendString:@"<html><head><style>table { width: 100%; } td { padding: 5px;font-size: 32px; }</style></head><body><table border='1'>"];

    NSArray *csvRows = [csvContent componentsSeparatedByString:@"\n"];
    for (NSString *row in csvRows) {
        NSArray *rowItems = [row componentsSeparatedByString:@","];
        [htmlContent appendString:@"<tr>"];
        for (NSString *item in rowItems) {
            [htmlContent appendFormat:@"<td>%@</td>", item];
        }
        [htmlContent appendString:@"</tr>"];
    }

    [htmlContent appendString:@"</table></body></html>"];

    return htmlContent;
}

@end
