//
//  StartScreen.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/8/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "StartScreen.h"
#import "DebugMenu.h"
#import "SignupScreen.h"
#import "UINavigationController+Pog.h"
#import "GameManager.h"
#import "PogUIUtility.h"
#import "SoundManager.h"
#import "ObjectivesMgr.h"

#if !defined(FINAL)
static const float kVersionWidth = 80.0f;
static const float kVersionHeight = 20.0f;
static const float kVersionX = 0.7f;

@interface StartScreen ()
{
    UILabel* _version;
    UIButton* _debugButton;
}
- (void)didPressDebug:(id)sender;
@end
#endif

@implementation StartScreen

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

#if !defined(FINAL)
    // version string
    CGRect versionRect = CGRectMake(kVersionX * self.view.bounds.size.width, 0.0f,
                                    kVersionWidth, kVersionHeight);
    _version = [[UILabel alloc] initWithFrame:versionRect];
    [_version setText:[PogUIUtility versionStringForCurConfig]];
    [_version setBackgroundColor:[UIColor clearColor]];
    [_version setAdjustsFontSizeToFitWidth:YES];
    [self.view addSubview:_version];
    
    _debugButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_debugButton setFrame:versionRect];
    [_debugButton setBackgroundColor:[UIColor clearColor]];
    [_debugButton addTarget:self action:@selector(didPressDebug:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_debugButton];
#endif
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
#if !defined(DEBUG)
    if([[ObjectivesMgr getInstance] hasCompletedNewUserObjectives])
    {
        [RevMobAds showFullscreenAd];
    }
#endif
    [[SoundManager getInstance] playMusic:@"background_default" doLoop:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)didPressStart:(id)sender 
{
    [[SoundManager getInstance] playClip:@"Pog_SFX_ArriveHome"];
    [[GameManager getInstance] validateConnectivity];
}

#if !defined(FINAL)
- (void)didPressDebug:(id)sender
{
    DebugMenu* menu = [[DebugMenu alloc] initWithNibName:@"DebugMenu" bundle:nil];
    [self.navigationController pushFromRightViewController:menu animated:YES];
}
#endif
@end
