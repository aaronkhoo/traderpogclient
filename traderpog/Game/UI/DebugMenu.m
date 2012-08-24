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

@interface DebugMenu ()
- (void) setupOnOff;
- (void) teardownOnOff;
@end

@implementation DebugMenu
@synthesize localDevSwitch;

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
    [self setupOnOff];
}

- (void)viewDidUnload
{
    [self teardownOnOff];
    [self setLocalDevSwitch:nil];
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
}

- (void) teardownOnOff
{
    DebugOptions* debugOptions = [DebugOptions getInstance];
    [self.localDevSwitch removeTarget:debugOptions action:@selector(setOnOffLocalDev:) forControlEvents:UIControlEventValueChanged];
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
@end
