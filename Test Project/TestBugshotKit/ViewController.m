//
//  ViewController.m
//  TestBugshotKit
//
//  Created by Marco Arment on 1/20/14.
//  Copyright (c) 2014 Marco Arment. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () {
    int alertNumber;
}

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)showAlertButtonTapped:(id)sender
{
    alertNumber++;
    [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Warning %d", alertNumber] message:@"Alerts happen." delegate:nil cancelButtonTitle:@"Accept Fate" otherButtonTitles:nil] show];
}

@end
