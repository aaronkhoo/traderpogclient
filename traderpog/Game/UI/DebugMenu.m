//
//  DebugMenu.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/8/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "DebugMenu.h"
#import "DebugOptions.h"
#import "UINavigationController+Pog.h"
#import "Player.h"
#import "GameManager.h"
#import "LoadingScreen.h"
#import "LoadingTransition.h"
#import "LeaderboardsScreen.h"
#import "Flyer.h"
#import "FlyerMgr.h"
#import "GuildMembershipUI.h"

@interface DebugMenu ()
{
    UIButton* _loadingPopButton;
}
- (void) setupOnOff;
- (void) teardownOnOff;
@end

@implementation DebugMenu
@synthesize localDevSwitch;
@synthesize speed100xSwitch;
@synthesize leaderboardsButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        _loadingPopButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [_loadingPopButton addTarget:self action:@selector(didPressPopButton:) forControlEvents:UIControlEventTouchUpInside];
        [_loadingPopButton setFrame:CGRectMake(10.0f, 10.0f, 37.0f, 37.0f)];
        [_loadingPopButton setTitle:@"D" forState:UIControlStateNormal];
    }
    return self;
}

- (void) dealloc
{
    NSLog(@"debug menu dealloc");
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupOnOff];
    
    // Disable leaderboards if no player exists
    if ([Player getInstance].playerId == 0)
    {
        leaderboardsButton.enabled = FALSE;
    }
}

- (void)viewDidUnload
{
    [self teardownOnOff];
    [self setLocalDevSwitch:nil];
    [self setSpeed100xSwitch:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) setupOnOff
{
    DebugOptions* debugOptions = [DebugOptions getInstance];
    [self.localDevSwitch addTarget:debugOptions action:@selector(setOnOffLocalDev:) forControlEvents:UIControlEventValueChanged];
    self.localDevSwitch.on = [debugOptions localDev];
    [self.speed100xSwitch addTarget:debugOptions action:@selector(setOnOffSpeed100x:) forControlEvents:UIControlEventValueChanged];
    self.speed100xSwitch.on = [debugOptions speed100x];
}

- (void) teardownOnOff
{
    DebugOptions* debugOptions = [DebugOptions getInstance];
    [self.localDevSwitch removeTarget:debugOptions action:@selector(setOnOffLocalDev:) forControlEvents:UIControlEventValueChanged];
    [self.speed100xSwitch removeTarget:debugOptions action:@selector(setOnOffSpeed100x:) forControlEvents:UIControlEventValueChanged];
}


- (IBAction)didPressClearCache:(id)sender
{
    [[GameManager getInstance] clearCache];
}

- (IBAction)didPressClose:(id)sender 
{
    [self.navigationController popToRightViewControllerAnimated:YES];
}

- (IBAction)didPressAdd200Coins:(id)sender
{
    [[Player getInstance] addBucks:200];
}

- (IBAction)didPressLeaderboards:(id)sender
{
    LeaderboardsScreen* leaderboards = [[LeaderboardsScreen alloc] initWithNibName:@"LeaderboardsScreen" bundle:nil];
    [self.navigationController pushFromRightViewController:leaderboards animated:YES];
}

- (IBAction)didPressFlyerUpgrade:(id)sender
{
    for(Flyer* cur in [[FlyerMgr getInstance] playerFlyers])
    {
        [cur applyUpgradeTier:0];
    }
}

- (void) didPressPopButton:(id)sender
{
    UIViewController* current = self.navigationController.visibleViewController;
    if([current isMemberOfClass:[LoadingScreen class]])
    {
        // call LoadingScreen dismiss so that it can do an outro anim before getting popped
        LoadingScreen* loadingScreen = (LoadingScreen*)current;
        [loadingScreen dismissWithCompletion:^(void){
            [self.navigationController popFadeOutToRootViewControllerAnimated:YES];
        }];
    }
}

- (IBAction)didPressLoading:(id)sender
{
    LoadingTransition* transition = [[LoadingTransition alloc] initWithNibName:@"LoadingTransition" bundle:nil];
    [self.navigationController pushFadeInViewController:transition animated:YES];
    
    LoadingScreen* screen = [[LoadingScreen alloc] initWithNibName:@"LoadingScreen" bundle:nil];
    [screen.view addSubview:_loadingPopButton];
    
    [self.navigationController pushFadeInViewController:screen animated:YES];
}

- (IBAction)didPressProducts:(id)sender
{
    GuildMembershipUI* guildmembership = [[GuildMembershipUI alloc] initWithNibName:@"GuildMembershipUI" bundle:nil];
    [self.navigationController pushFromRightViewController:guildmembership animated:YES];
}
@end
