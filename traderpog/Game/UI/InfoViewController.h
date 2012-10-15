//
//  InfoViewController.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/13/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ModalNavDelegate.h"

extern NSString* const kInfoViewModalId;
extern NSString* const kInfoLeaderboardId;
extern NSString* const kInfoMembershipId;
extern NSString* const kInfoMoreId;
extern NSString* const kInfoCloseId;

@class CircleButton;
@interface InfoViewController : UIViewController
@property (weak, nonatomic) IBOutlet CircleButton *closeCircle;
@property (weak, nonatomic) IBOutlet CircleButton *leaderboardsCircle;
@property (weak, nonatomic) IBOutlet CircleButton *memberCircle;
@property (weak, nonatomic) IBOutlet CircleButton *moreCircle;

- (id) initWithCenterFrame:(CGRect)centerFrame delegate:(NSObject<ModalNavDelegate>*)delegate;

- (void) presentInView:(UIView*)parentView belowSubview:(UIView*)subview animated:(BOOL)isAnimated;
- (void) dismissAnimated:(BOOL)isAnimated;
@end
