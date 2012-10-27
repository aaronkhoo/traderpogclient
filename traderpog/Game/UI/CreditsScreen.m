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

@interface CreditsScreen ()

@end

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
    [super viewDidUnload];
}
@end
