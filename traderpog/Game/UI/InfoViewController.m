//
//  InfoViewController.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/13/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "InfoViewController.h"
#import "PogUIUtility.h"
#import "CircleButton.h"
#import "LeaderboardsScreen.h"
#import "GuildMembershipUI.h"
#import "GameColors.h"
#import <QuartzCore/QuartzCore.h>

NSString* const kInfoViewModalId = @"InfoViewModal";
NSString* const kInfoLeaderboardId = @"InfoLeaderboard";
NSString* const kInfoMembershipId = @"InfoMembership";
NSString* const kInfoMoreId = @"InfoMore";
NSString* const kInfoCloseId = @"InfoClose";

static const float kCircleDist = 72.0f;
static const float kCloseBorderWidth = 4.0f;
static const float kBorderWidth = 5.0f;
static const float kBubbleOutScale = 1.4f;
static const float kBubbleInitScale = 0.1f;

@interface InfoViewController ()
{
    __weak NSObject<ModalNavDelegate>* _delegate;
}
- (void) didPressLeaderboard:(id)sender;
- (void) didPressMember:(id)sender;
- (void) didPressMore:(id)sender;
@end

@implementation InfoViewController
@synthesize centerFrame = _centerFrame;
- (id)initWithCenterFrame:(CGRect)centerFrame delegate:(NSObject<ModalNavDelegate> *)delegate
{
    self = [super initWithNibName:@"InfoViewController" bundle:nil];
    if(self)
    {
        _centerFrame = centerFrame;
        _delegate = delegate;
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    NSAssert(false, @"call initWithCenterFrame: to create InfoViewController");
    return nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // set up the frame so that it places right where the info button is
    CGRect infoRect = [PogUIUtility createCenterFrameWithSize:self.view.bounds.size inFrame:_centerFrame];
    self.view.frame = infoRect;
    
    [self.closeCircle setButtonTarget:self action:@selector(didPressClose:)];
    [self.leaderboardsCircle setButtonTarget:self action:@selector(didPressLeaderboard:)];
    [self.memberCircle setButtonTarget:self action:@selector(didPressMember:)];
    [self.moreCircle setButtonTarget:self action:@selector(didPressMore:)];
    
    // distribute sub-circles equidistance from center
    CGRect subCircleFrame = [PogUIUtility createCenterFrameWithSize:self.leaderboardsCircle.frame.size inFrame:self.closeCircle.frame];
    [self.leaderboardsCircle setFrame:subCircleFrame];
    [self.memberCircle setFrame:subCircleFrame];
    [self.moreCircle setFrame:subCircleFrame];
    
    [self.closeCircle setBorderColor:[GameColors borderColorScanWithAlpha:1.0f]];
    [self.closeCircle setBorderWidth:kCloseBorderWidth];
    [self.leaderboardsCircle setBorderColor:[GameColors borderColorScanWithAlpha:1.0f]];
    [self.leaderboardsCircle setBorderWidth:kBorderWidth];
    [self.memberCircle setBorderColor:[GameColors borderColorScanWithAlpha:1.0f]];
    [self.memberCircle setBorderWidth:kBorderWidth];
    [self.moreCircle setBorderColor:[GameColors borderColorScanWithAlpha:1.0f]];
    [self.moreCircle setBorderWidth:kBorderWidth];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
    [self.moreCircle removeButtonTarget];
    [self.memberCircle removeButtonTarget];
    [self.leaderboardsCircle removeButtonTarget];
    [self.closeCircle removeButtonTarget];
    [self setCloseCircle:nil];
    [self setLeaderboardsCircle:nil];
    [self setMemberCircle:nil];
    [self setMoreCircle:nil];
    [super viewDidUnload];
}

- (void) presentInView:(UIView *)parentView belowSubview:(UIView*)subview animated:(BOOL)isAnimated
{
    if(subview)
    {
        [parentView insertSubview:self.view belowSubview:subview];
    }
    else
    {
        [parentView addSubview:self.view];
    }

    CGPoint downVec = CGPointMake(0.0f, kCircleDist * 1.1f);
    CGPoint downVec2 = CGPointMake(0.0f, kCircleDist);
    CGAffineTransform leaderTransform = CGAffineTransformMakeRotation(2.15f * M_PI_4);
    CGAffineTransform memberTransform = CGAffineTransformMakeRotation(M_PI_4);
    CGAffineTransform moreTransform = CGAffineTransformMakeRotation(-0.15f * M_PI_4);
    CGPoint leaderVec = CGPointApplyAffineTransform(downVec, leaderTransform);
    CGPoint leaderVec2 = CGPointApplyAffineTransform(downVec2, leaderTransform);
    CGPoint memberVec = CGPointApplyAffineTransform(downVec, memberTransform);
    CGPoint memberVec2 = CGPointApplyAffineTransform(downVec2, memberTransform);
    CGPoint moreVec = CGPointApplyAffineTransform(downVec, moreTransform);
    CGPoint moreVec2 = CGPointApplyAffineTransform(downVec2, moreTransform);
    
    if(isAnimated)
    {
        static const float kOutwardDur = 0.1f;
        static const float kBounceDur = 0.05f;
        static const float kSpacingDur = 0.02f;
        
        [self.closeCircle setTransform:CGAffineTransformMakeScale(kBubbleInitScale, kBubbleInitScale)];
        [UIView animateWithDuration:0.2f
                         animations:^(void){
                             [self.closeCircle setTransform:CGAffineTransformMakeScale(1.0f, 1.0f)];
                         }
                         completion:nil];
        
        [self.leaderboardsCircle setTransform:CGAffineTransformMakeScale(kBubbleInitScale, kBubbleInitScale)];
        [UIView animateWithDuration:kOutwardDur
                              delay:0.0f
                            options:UIViewAnimationCurveEaseIn
                         animations:^(void){
                             CGAffineTransform s = CGAffineTransformMakeScale(kBubbleOutScale, kBubbleOutScale);
                             CGAffineTransform t = CGAffineTransformTranslate(s, leaderVec.x, leaderVec.y);
                             [self.leaderboardsCircle setTransform:t];
                         }
                         completion:^(BOOL finished){
                             if(finished)
                             {
                                 [UIView animateWithDuration:kBounceDur
                                                       delay:0.0f
                                                     options:UIViewAnimationCurveEaseIn
                                                  animations:^(void){
                                                      CGAffineTransform s = CGAffineTransformMakeScale(1.0f, 1.0f);
                                                      CGAffineTransform t = CGAffineTransformTranslate(s, leaderVec2.x, leaderVec2.y);
                                                      [self.leaderboardsCircle setTransform:t];
                                                  }
                                                  completion:nil];
                             }
                         }];
        
        [self.memberCircle setTransform:CGAffineTransformMakeScale(kBubbleInitScale, kBubbleInitScale)];
        [UIView animateWithDuration:kOutwardDur
                              delay:kSpacingDur
                            options:UIViewAnimationCurveEaseIn
                         animations:^(void){
                             CGAffineTransform s = CGAffineTransformMakeScale(kBubbleOutScale, kBubbleOutScale);
                             CGAffineTransform t = CGAffineTransformTranslate(s, memberVec.x, memberVec.y);
                             [self.memberCircle setTransform:t];
                         }
                         completion:^(BOOL finished){
                             if(finished)
                             {
                                 [UIView animateWithDuration:kBounceDur
                                                       delay:0.0f
                                                     options:UIViewAnimationCurveEaseIn
                                                  animations:^(void){
                                                      CGAffineTransform s = CGAffineTransformMakeScale(1.0f, 1.0f);
                                                      CGAffineTransform t = CGAffineTransformTranslate(s, memberVec2.x, memberVec2.y);
                                                      [self.memberCircle setTransform:t];
                                                  }
                                                  completion:nil];
                             }
                         }];
        
        [self.moreCircle setTransform:CGAffineTransformMakeScale(kBubbleInitScale, kBubbleInitScale)];
        [UIView animateWithDuration:kOutwardDur
                              delay:kSpacingDur * 2.0f
                            options:UIViewAnimationCurveEaseIn
                         animations:^(void){
                             CGAffineTransform s = CGAffineTransformMakeScale(kBubbleOutScale, kBubbleOutScale);
                             CGAffineTransform t = CGAffineTransformTranslate(s, moreVec.x, moreVec.y);
                             [self.moreCircle setTransform:t];
                         }
                         completion:^(BOOL finished){
                             if(finished)
                             {
                                 [UIView animateWithDuration:kBounceDur
                                                       delay:0.0f
                                                     options:UIViewAnimationCurveEaseIn
                                                  animations:^(void){
                                                      CGAffineTransform s = CGAffineTransformMakeScale(1.0f, 1.0f);
                                                      CGAffineTransform t = CGAffineTransformTranslate(s, moreVec2.x, moreVec2.y);
                                                      [self.moreCircle setTransform:t];
                                                  }
                                                  completion:nil];
                             }
                         }];
    }
    else
    {
        [self.closeCircle setTransform:CGAffineTransformMakeScale(1.0f, 1.0f)];

        CGAffineTransform s = CGAffineTransformMakeScale(1.0f, 1.0f);
        [self.leaderboardsCircle setTransform:CGAffineTransformTranslate(s, leaderVec2.x, leaderVec2.y)];
        [self.memberCircle setTransform:CGAffineTransformTranslate(s, memberVec2.x, memberVec2.y)];
        [self.moreCircle setTransform:CGAffineTransformTranslate(s, moreVec2.x, moreVec2.y)];
    }
}

- (void) dismissAnimated:(BOOL)isAnimated
{
    CGPoint downVec = CGPointMake(0.0f, kCircleDist * 1.1f);
    CGAffineTransform leaderTransform = CGAffineTransformMakeRotation(2.15f * M_PI_4);
    CGAffineTransform memberTransform = CGAffineTransformMakeRotation(M_PI_4);
    CGAffineTransform moreTransform = CGAffineTransformMakeRotation(-0.15f * M_PI_4);
    CGPoint leaderVec = CGPointApplyAffineTransform(downVec, leaderTransform);
    CGPoint memberVec = CGPointApplyAffineTransform(downVec, memberTransform);
    CGPoint moreVec = CGPointApplyAffineTransform(downVec, moreTransform);
    
    if(isAnimated)
    {
        static const float kOutwardDur = 0.1f;
        static const float kBounceDur = 0.05f;
        static const float kSpacingDur = 0.02f;
        
        [UIView animateWithDuration:0.3f
                         animations:^(void){
                             [self.closeCircle setTransform:CGAffineTransformMakeScale(0.1f, 0.1f)];
                         }
                         completion:^(BOOL finished){
                             [self.view removeFromSuperview];
                         }];
        
        [UIView animateWithDuration:kBounceDur
                              delay:0.0f
                            options:UIViewAnimationCurveEaseIn
                         animations:^(void){
                             CGAffineTransform s = CGAffineTransformMakeScale(1.8f, 1.8f);
                             CGAffineTransform t = CGAffineTransformTranslate(s, leaderVec.x, leaderVec.y);
                             [self.leaderboardsCircle setTransform:t];
                         }
                         completion:^(BOOL finished){
                             if(finished)
                             {
                                 [UIView animateWithDuration:kOutwardDur
                                                       delay:0.0f
                                                     options:UIViewAnimationCurveEaseIn
                                                  animations:^(void){
                                                      CGAffineTransform s = CGAffineTransformMakeScale(0.1f, 0.1f);
                                                      [self.leaderboardsCircle setTransform:s];
                                                  }
                                                  completion:nil];
                             }
                         }];
        
        [UIView animateWithDuration:kBounceDur
                              delay:kSpacingDur
                            options:UIViewAnimationCurveEaseIn
                         animations:^(void){
                             CGAffineTransform s = CGAffineTransformMakeScale(1.8f, 1.8f);
                             CGAffineTransform t = CGAffineTransformTranslate(s, memberVec.x, memberVec.y);
                             [self.memberCircle setTransform:t];
                         }
                         completion:^(BOOL finished){
                             if(finished)
                             {
                                 [UIView animateWithDuration:kOutwardDur
                                                       delay:0.0f
                                                     options:UIViewAnimationCurveEaseIn
                                                  animations:^(void){
                                                      CGAffineTransform s = CGAffineTransformMakeScale(0.1f, 0.1f);
                                                      [self.memberCircle setTransform:s];
                                                  }
                                                  completion:nil];
                             }
                         }];
        
        [UIView animateWithDuration:kBounceDur
                              delay:kSpacingDur * 2.0f
                            options:UIViewAnimationCurveEaseIn
                         animations:^(void){
                             CGAffineTransform s = CGAffineTransformMakeScale(1.8f, 1.8f);
                             CGAffineTransform t = CGAffineTransformTranslate(s, moreVec.x, moreVec.y);
                             [self.moreCircle setTransform:t];
                         }
                         completion:^(BOOL finished){
                             if(finished)
                             {
                                 [UIView animateWithDuration:kOutwardDur
                                                       delay:0.0f
                                                     options:UIViewAnimationCurveEaseIn
                                                  animations:^(void){
                                                      CGAffineTransform s = CGAffineTransformMakeScale(0.1f, 0.1f);
                                                      [self.moreCircle setTransform:s];
                                                  }
                                                  completion:nil];
                             }
                         }];
    }
    else
    {
        [self.view removeFromSuperview];
    }
}

#pragma mark - button actions
- (void) didPressClose:(id)sender
{
    [_delegate dismissModalView:self.view withModalId:kInfoCloseId];
}

- (void) didPressLeaderboard:(id)sender
{
    [_delegate dismissModalView:self.view withModalId:kInfoLeaderboardId];
}

- (void) didPressMember:(id)sender
{
    [_delegate dismissModalView:self.view withModalId:kInfoMembershipId];
}

- (void) didPressMore:(id)sender
{
    [_delegate dismissModalView:self.view withModalId:kInfoMoreId];
}

@end
