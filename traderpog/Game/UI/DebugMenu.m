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

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupOnOff];
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

- (void) didPressPopButton:(id)sender
{
    if([self.navigationController.visibleViewController isMemberOfClass:[LoadingScreen class]])
    {
        // need to stop displayLink on LoadingScreen before pop because if not, then the LoadingScreen
        // would be prevented from getting deallocated
        LoadingScreen* loadingScreen = (LoadingScreen*)[self.navigationController visibleViewController];
        [loadingScreen stopAnim];
    }
    [self.navigationController popFadeOutViewControllerAnimated:YES];
}

- (IBAction)didPressLoading:(id)sender
{
    LoadingScreen* screen = [[LoadingScreen alloc] initWithNibName:@"LoadingScreen" bundle:nil];
    [screen.view addSubview:_loadingPopButton];
    
    [self.navigationController pushFadeInViewController:screen animated:YES];
}
@end
