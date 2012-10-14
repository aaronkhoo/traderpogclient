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
#import <QuartzCore/QuartzCore.h>

NSString* const kInfoViewModalId = @"InfoViewModal";
static const float kCircleDist = 47.5f;

@interface InfoViewController ()
{
    CGRect _centerFrame;
    __weak NSObject<ModalNavDelegate>* _delegate;
}
- (void) didPressLeaderboard:(id)sender;
- (void) didPressMember:(id)sender;
- (void) didPressMore:(id)sender;
@end

@implementation InfoViewController

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
    [self.leaderboardsCircle setFrame:self.closeCircle.frame];
    [self.memberCircle setFrame:self.closeCircle.frame];
    [self.moreCircle setFrame:self.closeCircle.frame];
    
    CGPoint downVec = CGPointMake(0.0f, kCircleDist);
    CGAffineTransform leaderTransform = CGAffineTransformMakeRotation(2.2f * M_PI_4);
    CGAffineTransform memberTransform = CGAffineTransformMakeRotation(M_PI_4);
    CGAffineTransform moreTransform = CGAffineTransformMakeRotation(-0.2f * M_PI_4);
    CGPoint leaderVec = CGPointApplyAffineTransform(downVec, leaderTransform);
    [self.leaderboardsCircle setTransform:CGAffineTransformMakeTranslation(leaderVec.x, leaderVec.y)];
    CGPoint memberVec = CGPointApplyAffineTransform(downVec, memberTransform);
    [self.memberCircle setTransform:CGAffineTransformMakeTranslation(memberVec.x, memberVec.y)];
    CGPoint moreVec = CGPointApplyAffineTransform(downVec, moreTransform);
    [self.moreCircle setTransform:CGAffineTransformMakeTranslation(moreVec.x, moreVec.y)];
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

#pragma mark - button actions
- (void) didPressClose:(id)sender
{
    [_delegate dismissModalView:self.view withModalId:kInfoViewModalId];
}

- (void) didPressLeaderboard:(id)sender
{
    NSLog(@"leaderboard");
    [_delegate dismissModalView:self.view withModalId:kInfoViewModalId];
}

- (void) didPressMember:(id)sender
{
    NSLog(@"member");
    [_delegate dismissModalView:self.view withModalId:kInfoViewModalId];
}

- (void) didPressMore:(id)sender
{
    NSLog(@"more");
    [_delegate dismissModalView:self.view withModalId:kInfoViewModalId];
}

@end
