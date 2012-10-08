//
//  FlyerLabViewController.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/7/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "FlyerLabViewController.h"
#import "GameColors.h"
#import "UINavigationController+Pog.h"
#import "FlyerCustomize.h"
#import "FlyerUpgrade.h"
#import "Flyer.h"
#import "PogUIUtility.h"

static const float kContentBorderWidth = 6.0f;
static const float kContentBorderCornerRadius = 8.0f;

@interface FlyerLabViewController ()
- (void) didPressClose:(id)sender;
@end

@implementation FlyerLabViewController
@synthesize flyer = _flyer;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self)
    {
        _flyer = nil;
    }
    return self;
}

- (void) dealloc
{
    [self.closeCircle removeButtonTarget];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.alpha = 1.0f;
    [PogUIUtility setBorderOnView:self.contentView
                            width:kContentBorderWidth
                            color:[GameColors borderColorScanWithAlpha:1.0f]
                     cornerRadius:kContentBorderCornerRadius];

    [self.closeCircle setBorderColor:[GameColors borderColorScanWithAlpha:1.0f]];
    [self.closeCircle setButtonTarget:self action:@selector(didPressClose:)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
    [self.closeCircle removeButtonTarget];
    [self setContentView:nil];
    [self setCloseCircle:nil];
    [super viewDidUnload];
}

#pragma mark - button actions
- (void) didPressClose:(id)sender
{
    self.flyer = nil;
    [UIView animateWithDuration:0.2f
                     animations:^(void){
                         self.view.alpha = 0.0f;
                     }
                     completion:^(BOOL finished){
                         [self.navigationController popViewControllerAnimated:NO];
                     }];
}

- (IBAction)didPressCustomize:(id)sender
{
    FlyerCustomize* next = [[FlyerCustomize alloc] initWithNibName:@"FlyerCustomize" bundle:nil];
    [self.navigationController pushFromRightViewController:next animated:YES];
}

- (IBAction)didPressUpgrade:(id)sender
{
    /*
    if([self flyer])
    {
        [self.flyer applyUpgradeTier:1];
    }
    */
    FlyerUpgrade* next = [[FlyerUpgrade alloc] initWithNibName:@"FlyerUpgrade" bundle:nil];
    [self.navigationController pushFromRightViewController:next animated:YES];
}
@end
