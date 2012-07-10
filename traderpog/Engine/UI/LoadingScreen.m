//
//  LoadingScreen.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "LoadingScreen.h"

@interface LoadingScreen ()
- (void) initBackgroundColor;
@end

@implementation LoadingScreen
@synthesize bigLabel = _bigLabel;
@synthesize progressLabel = _progressLabel;
@synthesize activityIndicator = _activityIndicator;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) 
    {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initBackgroundColor];
}

- (void)viewDidUnload
{
    _bigLabel = nil;
    _progressLabel = nil;
    _activityIndicator = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - internal methods
- (void) initBackgroundColor
{
    [self.view setBackgroundColor:[UIColor colorWithRed:237.0f/255.0f green:28.0f/255.0f blue:36.0f/255.0f alpha:1.0f]];
}


@end
