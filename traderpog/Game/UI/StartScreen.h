//
//  StartScreen.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/8/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StartScreen : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;


- (IBAction)didPressStart:(id)sender;
- (IBAction)didPressDebug:(id)sender;

@end
