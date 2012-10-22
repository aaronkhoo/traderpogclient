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
#import "FlyerLabFactory.h"
#import "PogUIUtility.h"
#import "ImageManager.h"
#import "FlyerTypes.h"
#import "FlyerType.h"

static const float kContentBorderWidth = 6.0f;
static const float kContentBorderCornerRadius = 8.0f;
static const float kButtonViewBorderWidth = 4.0f;

@interface FlyerLabViewController ()
- (void) setupContent;
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
    [self.contentView setBackgroundColor:[GameColors bubbleColorFlyersWithAlpha:1.0f]];
    [self.closeCircle setBorderColor:[GameColors borderColorScanWithAlpha:1.0f]];
    [self.closeCircle setButtonTarget:self action:@selector(didPressClose:)];
    [PogUIUtility setBorderOnView:self.upgradeView
                            width:kButtonViewBorderWidth
                            color:[GameColors borderColorScanWithAlpha:1.0f]
                     cornerRadius:kContentBorderCornerRadius];
    [self.upgradeView setBackgroundColor:[GameColors bubbleColorScanWithAlpha:1.0f]];
    [PogUIUtility setBorderOnView:self.customizeView
                            width:kButtonViewBorderWidth
                            color:[GameColors borderColorScanWithAlpha:1.0f]
                     cornerRadius:kContentBorderCornerRadius];
    [self.customizeView setBackgroundColor:[GameColors bubbleColorScanWithAlpha:1.0f]];
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
    [self setUpgradeButton:nil];
    [self setImageView:nil];
    [self setContentSubview:nil];
    [self setTitleView:nil];
    [self setUpgradeView:nil];
    [self setCustomizeView:nil];
    [super viewDidUnload];
}

- (void) viewWillAppear:(BOOL)animated
{
    if([self flyer])
    {
        [self.upgradeButton setEnabled:YES];
    }
    [self setupContent];
}

#pragma mark - internal methods
- (void) setupContent
{
    if(_flyer)
    {
        // image
        NSString* flyerTypeName = [[FlyerTypes getInstance] sideImgForFlyerTypeAtIndex:[_flyer flyerTypeIndex]];
        NSString* imageName = [[FlyerLabFactory getInstance] sideImageForFlyerTypeNamed:flyerTypeName tier:[_flyer curUpgradeTier] colorIndex:[_flyer curColor]];
        UIImage* image = [[ImageManager getInstance] getImage:imageName];
        [self.imageView setImage:image];
    }
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
    if([self flyer])
    {
        FlyerCustomize* next = [[FlyerCustomize alloc] initWithFlyer:self.flyer];
        [self.navigationController pushFadeInViewController:next animated:YES];
    }
}

- (IBAction)didPressUpgrade:(id)sender
{
    if([self flyer])
    {
        FlyerUpgrade* next = [[FlyerUpgrade alloc] initWithFlyer:self.flyer];
        [self.navigationController pushFadeInViewController:next animated:YES];
    }
}
@end
