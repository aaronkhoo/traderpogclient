//
//  NewHomeSelectItem.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/13/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "NewHomeSelectItem.h"

@interface NewHomeSelectItem ()

@end

@implementation NewHomeSelectItem
@synthesize imageLeft;
@synthesize imageMiddle;
@synthesize imageRight;
@synthesize labelLeft;
@synthesize labelMiddle;
@synthesize labelRight;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [self setLabelLeft:nil];
    [self setLabelMiddle:nil];
    [self setLabelRight:nil];
    [self setImageLeft:nil];
    [self setImageMiddle:nil];
    [self setImageRight:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)didPressOkLeft:(id)sender 
{
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (IBAction)didPressOkMiddle:(id)sender 
{
}

- (IBAction)didPressOkRight:(id)sender 
{
}
@end
