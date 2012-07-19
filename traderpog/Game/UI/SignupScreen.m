//
//  SignupScreen.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "SignupScreen.h"
#import "PogUIUtility.h"
#import "LoadingScreen.h"
#import "UINavigationController+Pog.h"
#import "GameManager.h"
#import "Player.h"

@interface SignupScreen ()

@end

@implementation SignupScreen

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
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)createNewAccount
{
    // show loading screen and commence new player sequence
    LoadingScreen* loading = [[LoadingScreen alloc] initWithNibName:@"LoadingScreen" bundle:nil];
    loading.progressLabel.text = @"Creating Account";
    [self.navigationController pushFadeInViewController:loading animated:YES];

    // Calling server to create new account
    [[Player getInstance] createNewPlayerOnServer:@""];
}

- (IBAction)connectToFacebook:(id)sender {
}

@end
