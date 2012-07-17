//
//  SignupScreen.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SignupScreen : UIViewController<UITextFieldDelegate>

- (IBAction)createNewAccount;
- (IBAction)connectToFacebook:(id)sender;

@end
