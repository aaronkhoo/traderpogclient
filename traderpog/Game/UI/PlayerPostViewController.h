//
//  PlayerPostViewController.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/19/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ModalNavDelegate.h"

extern NSString* const kMyPostMenuCloseId;

@class CircleButton;
@class MyTradePost;
@interface PlayerPostViewController : UIViewController
{
    CGRect _centerFrame;
    __weak MyTradePost* _myPost;
}
@property (nonatomic) CGRect centerFrame;
@property (nonatomic,weak) MyTradePost* myPost;
@property (weak, nonatomic) IBOutlet CircleButton *closeCircle;
@property (weak, nonatomic) IBOutlet CircleButton *restockCircle;
@property (weak, nonatomic) IBOutlet UIView *beaconBar;
@property (weak, nonatomic) IBOutlet UIView *flyerBar;
@property (weak, nonatomic) IBOutlet UIView *restockBar;
@property (weak, nonatomic) IBOutlet UILabel *flyerLabel;

- (id) initWithCenterFrame:(CGRect)centerFrame
                  delegate:(NSObject<ModalNavDelegate>*)delegate;

- (void) presentInView:(UIView*)parentView belowSubview:(UIView*)subview animated:(BOOL)isAnimated;
- (void) dismissAnimated:(BOOL)isAnimated;
- (IBAction)didPressBackground:(id)sender;

@end
