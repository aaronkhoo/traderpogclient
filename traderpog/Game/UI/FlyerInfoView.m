//
//  FlyerInfoView.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/23/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "FlyerInfoView.h"
#import "PogUIUtility.h"
#import "GameColors.h"
#import "ImageManager.h"
#import "CircleButton.h"
#import "Flyer.h"
#import "FlyerTypes.h"
#import "FlyerLabFactory.h"
#import "FlyerUpgradePack.h"
#import "TradeItemTypes.h"
#import "TradeItemType.h"
#import "FlyerAnnotationView.h"
#import "GameManager.h"
#import "FlyerMgr.h"

NSString* const kFlyerInfoViewReuseIdentifier = @"FlyerInfoView";
static const float kBorderWidth = 6.0f;
static const float kCircleBorderWidth = 2.0f;
static const float kGoBorderWidth = 6.0f;
static const float kBorderCornerRadius = 8.0f;
static const float kDisabledAlpha = 0.6f;

@interface FlyerInfoView ()
{
    Flyer* _flyer;
}
@end

@implementation FlyerInfoView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [[NSBundle mainBundle] loadNibNamed:@"FlyerInfoView" owner:self options:nil];
        [PogUIUtility setBorderOnView:self.nibContentView
                                width:kBorderWidth
                                color:[GameColors bubbleColorFlyersWithAlpha:1.0f]
                         cornerRadius:kBorderCornerRadius];
        [self.contentScrim setBackgroundColor:[GameColors bgColorFlyersWithAlpha:0.85f]];
        [self.closeCircle setBorderWidth:kCircleBorderWidth];
        [self.closeCircle setBorderColor:[GameColors bubbleColorFlyersWithAlpha:1.0f]];
        [self.closeCircle setBackgroundColor:[GameColors bgColorFlyersWithAlpha:1.0f]];
        [self.goCircle setBorderWidth:kGoBorderWidth];
        [self.goCircle setBorderColor:[GameColors bubbleColorFlyersWithAlpha:1.0f]];
        [self.goCircle setBackgroundColor:[GameColors bgColorFlyersWithAlpha:1.0f]];
        [self.nibTitleView setBackgroundColor:[GameColors bubbleColorFlyersWithAlpha:1.0f]];

        [self addSubview:self.nibView];
        [self setBackgroundColor:[UIColor clearColor]];
        
        _flyer = nil;
    }
    return self;
}

static NSString* const kDefaultFlyerTypeName = @"flyer_glider";
static const unsigned int kDefaultFlyerTypeCapacity = 80;
static NSString* const kDefaultFlyerTypeTitle = @"Flyer";

- (void) refreshViewForFlyer:(Flyer *)flyer
{
    _flyer = flyer;
    
    // info from FlyerType
    NSString* flyerTypeName = kDefaultFlyerTypeName;
    unsigned int flyerTypeCap = kDefaultFlyerTypeCapacity;
    NSString* flyerTypeTitle = kDefaultFlyerTypeTitle;
    {
        FlyerType* flyerType = [[FlyerTypes getInstance] getFlyerTypeAtIndex:[flyer flyerTypeIndex]];
        if(flyerType)
        {
            flyerTypeName = [flyerType sideimg];
            flyerTypeCap = [flyerType capacity];
            flyerTypeTitle = [flyerType name];
        }
    }

    // image
    NSString* imageName = [[FlyerLabFactory getInstance] sideImageForFlyerTypeNamed:flyerTypeName tier:[flyer curUpgradeTier] colorIndex:[flyer curColor]];
    UIImage* image = [[ImageManager getInstance] getImage:imageName];
    [self.imageView setImage:image];

    // title
    [self.titleLabel setText:flyerTypeTitle];
    
    // trade item info
    NSString* itemId = [flyer.inventory itemId];
    if(!itemId)
    {
        itemId = [flyer.inventory orderItemId];
    }
    TradeItemType* itemType = [[TradeItemTypes getInstance] getItemTypeForId:itemId];
    NSString* itemName = nil;
    if(itemType)
    {
        // item image
        NSString* itemImagePath = [itemType imgPath];
        itemName = [itemType name];
        UIImage* itemImage = [[ImageManager getInstance] getImage:itemImagePath];
        [self.itemImageView setImage:itemImage];
        [self.itemImageView setHidden:NO];
        
        // item name
        [self.itemNameLabel setText:itemName];
    }
    else
    {
        [self.itemImageView setHidden:YES];
        [self.itemNameLabel setText:@"No Item"];
    }
    
    
    // num items
    unsigned int numItems = [flyer.inventory orderNumItems] + [flyer.inventory numItems];
    NSString* numText = [PogUIUtility commaSeparatedStringFromUnsignedInt:numItems];
    [self.itemNumLabel setText:[NSString stringWithFormat:@"x%@",numText]];

    // capacity
    FlyerUpgradePack* curPack = [[FlyerLabFactory getInstance] upgradeForTier:[flyer curUpgradeTier]];
    unsigned int cap = flyerTypeCap * [curPack capacityFactor];
    if(numItems < cap)
    {
        // show percentage
        unsigned int percent = 100 * ((float)(numItems)) / ((float)cap);
        [self.capacityLabel setText:[NSString stringWithFormat:@"%d%%", percent]];
    }
    else
    {
        // show full
        [self.capacityLabel setText:@"FULL"];
    }
    
    // flyer state
    if(kFlyerStateEnroute == [flyer state])
    {
        [self.goCircle setHidden:YES];
        [self.flyerStateLabel setHidden:YES];
    }
    /*
    else if([[FlyerMgr getInstance] homeOrHomeboundFlyer])
    {
        // can't go home
        [self.goCircle setHidden:NO];
        [self.goLabel setAlpha:kDisabledAlpha];
        [self.homeLabel setAlpha:kDisabledAlpha];
        [self.flyerStateLabel setText:[flyer displayNameOfFlyerState]];
        [self.flyerStateLabel setHidden:NO];
    }
     */
    else
    {
        [self.goCircle setHidden:NO];
        [self.goLabel setAlpha:1.0f];
        [self.homeLabel setAlpha:1.0f];
        [self.flyerStateLabel setText:[flyer displayNameOfFlyerState]];
        [self.flyerStateLabel setHidden:NO];
    }
    
    // time till dest
    if(kFlyerStateEnroute == [flyer state])
    {
        [self.timeTillDestLabel setHidden:NO];
        [self.timeTillDestTitle setHidden:NO];
        [self.timeTillDestLabel setText:[PogUIUtility stringFromTimeInterval:[flyer timeTillDest]]];
    }
    else
    {
        [self.timeTillDestLabel setHidden:YES];
        [self.timeTillDestTitle setHidden:YES];
    }
    [flyer addObserver:self forKeyPath:kKeyFlyerMetersToDest options:0 context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context
{
    if([object isMemberOfClass:[Flyer class]])
    {
        Flyer* flyer = (Flyer*)object;
        if([keyPath isEqualToString:kKeyFlyerMetersToDest])
        {
            // add 1 second as a fake roundup (so that when time is less than 1 second but larger than
            // 0), user would see 1 sec
            NSTimeInterval timeTillDest = [flyer timeTillDest] + 1.0f;
            NSString* timerString = [PogUIUtility stringFromTimeInterval:timeTillDest];
            [self.timeTillDestLabel setText:timerString];
        }
    }
}

#pragma mark - ViewReuseDelegate
- (NSString*) reuseIdentifier
{
    return kFlyerInfoViewReuseIdentifier;
}

- (void) prepareForQueue
{
    [self.closeCircle removeButtonTarget];
    [self.goCircle removeButtonTarget];
    if(_flyer)
    {
        [_flyer removeObserver:self forKeyPath:kKeyFlyerMetersToDest];
        _flyer = nil;
    }
}

@end
