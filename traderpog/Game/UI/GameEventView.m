//
//  GameEventView.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 9/29/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "GameEventView.h"
#import "PogUIUtility.h"
#import "GameEvent.h"
#import "MapControl.h"
#import "GameColors.h"
#import "GameManager.h"
#import "GameViewController.h"

const float kGameEventViewVisibleSecs = 5.0f;

static const float kGameEventViewTopOffset = 0.15f;
static const float kGameEventViewWidth = 305.0f;
static const float kGameEventViewHeight = 60.0f;
static const float kGameEventViewHInset = 4.0f;
static const float kGameEventViewWInset = 4.0f;
static const float kGameEventLabelWInset = 10.0f;
static const float kGameEventLabelHInset = 6.0f;
static const float kGameEventImageWHRatio = 1.3f;
static const float kGameEventBorderWidth = 3.0f;

static NSString* const kGameEventMessages[kGameEventTypesNum] =
{
    @"Flyer Arrived",                       // kGameEvent_FlyerArrival
    @"Loading Completed",                   // kGameEvent_LoadingCompleted
    @"Unloading Completed",                 // kGameEvent_UnloadingCompleted
    @"Your Flyer encountered a Storm",      // kGameEvent_FlyerStormed
    @"Your Trade Post is out of supply",    // kGameEvent_PostNeedsRestocking
    @"Your Beacon has expired"              // kGameEvent_BeaconExpired
};

@interface GameEventView ()
{
    CLLocation* _targetLocation;
    __weak MapControl* _targetMap;
}
@property (nonatomic,strong) UIImageView* imageView;
@property (nonatomic,strong) UIView* infoView;
@property (nonatomic,strong) UILabel* infoLabel;
@property (nonatomic,strong) UIButton* button;

- (void) reset;
- (void) initLayoutInRect:(CGRect)rect;
- (void) didPressView:(id)sender;
@end

@implementation GameEventView
@synthesize imageView;
@synthesize infoView;
@synthesize infoLabel;
@synthesize button;

- (id)initWithFrame:(CGRect)frame
{
    float originX = (0.5f * (frame.size.width - kGameEventViewWidth)) + frame.origin.x;
    float originY = (kGameEventViewTopOffset * frame.size.height) + frame.origin.y;
    CGRect eventFrame = CGRectMake(originX, originY, kGameEventViewWidth, kGameEventViewHeight);
    self = [super initWithFrame:eventFrame];
    if (self)
    {
        CGRect layoutRect = CGRectMake(0.0f, 0.0f, kGameEventViewWidth, kGameEventViewHeight);
        [self initLayoutInRect:layoutRect];
        
        [self setBackgroundColor:[UIColor blueColor]];
        [PogUIUtility setBorderOnView:self width:kGameEventBorderWidth color:[UIColor orangeColor]];
        [PogUIUtility setRoundCornersForView:self withCornerRadius:4.0f];
        
        _targetMap = nil;
        _targetLocation = nil;
    }
    return self;
}


- (void) refreshWithGameEvent:(GameEvent *)gameEvent targetMap:(MapControl*)map
{
    if([gameEvent eventType] < kGameEventTypesNum)
    {
        [self.infoLabel setText:kGameEventMessages[gameEvent.eventType]];
        _targetMap = map;
        _targetLocation = [[CLLocation alloc] initWithLatitude:gameEvent.coord.latitude longitude:gameEvent.coord.longitude];
        
        // color
        UIColor* borderColor = [GameColors borderColorFlyersWithAlpha:1.0f];
        UIColor* infoColor = [GameColors bubbleColorFlyersWithAlpha:1.0f];
        switch([gameEvent eventType])
        {
            case kGameEvent_PostNeedsRestocking:
                borderColor = [GameColors borderColorPostsWithAlpha:1.0f];
                infoColor = [GameColors bubbleColorPostsWithAlpha:1.0f];
                break;
                
            case kGameEvent_BeaconExpired:
                borderColor = [GameColors borderColorBeaconsWithAlpha:1.0f];
                infoColor = [GameColors bubbleColorBeaconsWithAlpha:1.0f];
                break;
                
            case kGameEvent_FlyerArrival:
            case kGameEvent_LoadingCompleted:
            case kGameEvent_UnloadingCompleted:
            case kGameEvent_FlyerStormed:
            default:
                // do nothing, use defaults from initializer
                break;
        }
        [self setBackgroundColor:borderColor];
        [PogUIUtility setBorderOnView:self width:kGameEventBorderWidth color:borderColor];
        [self.infoView setBackgroundColor:infoColor];
    }
}

#pragma mark - internal methods
- (void) reset
{
    _targetLocation = nil;
    _targetMap = nil;
}

- (void) initLayoutInRect:(CGRect)rect
{
    CGRect imageRect = CGRectMake(0.0f, 0.0f, kGameEventViewHeight * kGameEventImageWHRatio, kGameEventViewHeight);
    CGRect imageFrame = CGRectInset(imageRect, kGameEventViewHInset, kGameEventViewHInset);
    CGRect infoRect = CGRectMake(imageRect.origin.x + imageRect.size.width, 0.0f,
                                 kGameEventViewWidth - imageRect.size.width, kGameEventViewHeight);
    CGRect infoFrame = CGRectInset(infoRect, kGameEventViewWInset, kGameEventViewHInset);
    CGRect labelRect = CGRectMake(0.0f, 0.0f, infoRect.size.width, infoRect.size.height);
    CGRect labelFrame = CGRectInset(labelRect, kGameEventLabelWInset, kGameEventLabelHInset);
    
    self.imageView = [[UIImageView alloc] initWithFrame:imageFrame];
    [self.imageView setImage:[UIImage imageNamed:@"checkerboard.png"]];
    [self addSubview:[self imageView]];
    
    self.infoView = [[UIView alloc] initWithFrame:infoFrame];
    [self.infoView setBackgroundColor:[UIColor blueColor]];
    [self addSubview:[self infoView]];
    
    self.infoLabel = [[UILabel alloc] initWithFrame:labelFrame];
    [self.infoLabel setTextAlignment:UITextAlignmentLeft];
    [self.infoLabel setFont:[UIFont fontWithName:@"Marker Felt" size:16.0f]];
    [self.infoLabel setAdjustsFontSizeToFitWidth:YES];
    [self.infoLabel setNumberOfLines:2];
    [self.infoLabel setText:@"Hello\nHello"];
    [self.infoLabel setBackgroundColor:[UIColor clearColor]];
    [self.infoLabel setTextColor:[UIColor whiteColor]];
    
    [self.infoView addSubview:[self infoLabel]];
    
    self.button = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.button setFrame:[self bounds]];
    [self.button setBackgroundColor:[UIColor clearColor]];
    [self.button addTarget:self action:@selector(didPressView:) forControlEvents:UIControlEventTouchUpInside];

    [self addSubview:[self button]];
}

- (void) didPressView:(id)sender
{
    if(_targetMap && _targetLocation)
    {
        // dismiss any active wheel
        [[[GameManager getInstance] gameViewController] dismissActiveWheelAnimated:YES];

        // dismiss myself
        [self setHidden:YES];
        
        // center map
        [_targetMap centerOn:[_targetLocation coordinate] animated:YES];
    }
}

@end
