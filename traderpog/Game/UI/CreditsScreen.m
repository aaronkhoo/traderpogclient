//
//  CreditsScreen.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/27/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "CreditsScreen.h"
#import "UINavigationController+Pog.h"
#import "GameColors.h"
#import "CircleButton.h"
#import "PogUIUtility.h"
#import "DebugMenu.h"


#if !defined(FINAL)
@interface CreditsScreen ()
{
    UIButton* _debugButton;
}
- (void)didPressDebug:(id)sender;
@end
#endif

@implementation CreditsScreen

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
    [self.closeCircle setBorderColor:[GameColors borderColorScanWithAlpha:1.0f]];
    [self.closeCircle setButtonTarget:self action:@selector(didPressClose:)];
    [self.versionLabel setText:[PogUIUtility versionStringForCurConfig]];
    
#if !defined(FINAL)
    // debug button
    CGRect buttonRect = self.versionLabel.frame;
    _debugButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_debugButton setFrame:buttonRect];
    [_debugButton setBackgroundColor:[UIColor clearColor]];
    [_debugButton addTarget:self action:@selector(didPressDebug:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_debugButton];
#endif

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)didPressClose:(id)sender
{
    [self.navigationController popToRightViewControllerAnimated:YES];
}


- (void)viewDidUnload {
    [self setCloseCircle:nil];
    [self setVersionLabel:nil];
    [super viewDidUnload];
}


#if !defined(FINAL)
- (void)didPressDebug:(id)sender
{
    DebugMenu* menu = [[DebugMenu alloc] initWithNibName:@"DebugMenu" bundle:nil];
    [self.navigationController pushFromRightViewController:menu animated:YES];
}
#endif

@end
