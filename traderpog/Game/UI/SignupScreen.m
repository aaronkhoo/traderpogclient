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
    // Calling server to create new account
    [[Player getInstance] createNewPlayerOnServer:@""];
    
    // show loading screen and commence new player sequence
    LoadingScreen* loading = [[LoadingScreen alloc] initWithNibName:@"LoadingScreen" bundle:nil];
    [self.navigationController pushFadeInViewController:loading animated:YES];
}

/*
#pragma mark - UITextFieldDelegate
- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    // dismiss the keyboard
    [textField resignFirstResponder];
    
    return NO;
}

- (void) textFieldDidEndEditing:(UITextField *)textField
{
    NSString* text = [PogUIUtility stringTrimAllWhitespaces:[textField text]];
    if([text length])
    {
        NSString* userEmail = [textField text];
        
        // set email in config and proceed to signup completion
        NSLog(@"Signing up for %@", userEmail);
        
        // use the user portion of the email as the player's name initially
        NSArray* components = [userEmail componentsSeparatedByString:@"@"];
        if([components count])
        {
            NSLog(@"player name %@", [components objectAtIndex:0]);
        }
        
        // show loading screen and commence new player sequence
        LoadingScreen* loading = [[LoadingScreen alloc] initWithNibName:@"LoadingScreen" bundle:nil];
        [self.navigationController pushFadeInViewController:loading animated:YES];

        [[GameManager getInstance] setupNewPlayerWithEmail:userEmail loadingScreen:loading];
    }
}
*/

@end
