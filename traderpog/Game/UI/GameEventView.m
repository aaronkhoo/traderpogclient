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

static const float kGameEventViewTopOffset = 0.15f;
static const float kGameEventViewWidth = 305.0f;
static const float kGameEventViewHeight = 60.0f;
static const float kGameEventViewHInset = 1.0f;
static const float kGameEventViewWInset = 4.0f;
static const float kGameEventLabelWInset = 10.0f;
static const float kGameEventLabelHInset = 6.0f;
static const float kGameEventImageWHRatio = 1.3f;

static NSString* const kGameEventMessages[kGameEventTypesNum] =
{
    @"Flyer Arrived",       // kGameEvent_FlyerArrival
    @"Loading Completed"    //kGameEvent_LoadingCompleted
};

@interface GameEventView ()
@property (nonatomic,strong) UIImageView* imageView;
@property (nonatomic,strong) UIView* infoView;
@property (nonatomic,strong) UILabel* infoLabel;

- (void) initLayoutInRect:(CGRect)rect;
@end

@implementation GameEventView

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
        [PogUIUtility setBorderOnView:self width:5.0f color:[UIColor orangeColor]];
        [PogUIUtility setRoundCornersForView:self];
    }
    return self;
}

- (void) setPrimaryColor:(UIColor *)color
{
    [self setBackgroundColor:color];
    [PogUIUtility setBorderOnView:self width:5.0f color:color];
}

- (void) refreshWithGameEvent:(GameEvent *)gameEvent
{
    if([gameEvent eventType] < kGameEventTypesNum)
    {
        [self.infoLabel setText:kGameEventMessages[gameEvent.eventType]];
    }
}

#pragma mark - internal methods
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
}

@end
