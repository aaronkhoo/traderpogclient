//
//  SignupScreen.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SignupScreen : UIViewController<UITextFieldDelegate>
{
    __weak IBOutlet UIView *_contentView;
    __weak IBOutlet UITextField *_textField;
}
@end
