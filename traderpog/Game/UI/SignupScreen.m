//
//  SignupScreen.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "SignupScreen.h"
#import "PogUIUtility.h"

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

    [PogUIUtility createScrimAndBorderForView:_contentView];    
    _textField.delegate = self;
    
    // show keyboard immediately
    [_textField becomeFirstResponder];
}

- (void)viewDidUnload
{
    _textField = nil;
    _contentView = nil;
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

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
        
        NSLog(@"proceed to setting up new player");
        // TODO: register account
        // TODO: this is where a new view-controller can be pushed to show progress of account registration
    }
}


@end
