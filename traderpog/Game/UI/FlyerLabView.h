//
//  FlyerLabView.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/5/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewReuseDelegate.h"

extern NSString* const kFlyerLabViewReuseIdentifier;

@class CircleButton;
@interface FlyerLabView : UIView<ViewReuseDelegate>
@property (strong, nonatomic) IBOutlet UIView *nibView;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet CircleButton *closeCircle;

- (void) addButtonTarget:(id)target;
- (IBAction)didPressCustomize:(id)sender;
- (IBAction)didPressUpgrade:(id)sender;

@end
