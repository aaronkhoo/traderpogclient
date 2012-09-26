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

@interface StartScreen ()

@end

@implementation StartScreen

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

    // version string
    NSString *versionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey];
    [self.versionLabel setText:[NSString stringWithFormat:@"%@", versionString]];
}

- (void)viewDidUnload
{
    [self setVersionLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)didPressStart:(id)sender 
{
    [[GameManager getInstance] validateConnectivity];
}

- (IBAction)didPressDebug:(id)sender 
{
    DebugMenu* menu = [[DebugMenu alloc] initWithNibName:@"DebugMenu" bundle:nil];
    [self.navigationController pushFromRightViewController:menu animated:YES];
}
@end
