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
}

- (void) OpenMwSensorConnectionView
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    MwSesnsorConnectionViewController *nextViewController = [storyboard instantiateViewControllerWithIdentifier:@"MwSesnsorConnectionViewController"];
    [self presentViewController:nextViewController animated:YES completion:nil];

}

- (IBAction)ConnectButtonPressed:(id)sender {
    [self OpenMwSensorConnectionView];
}

@end
