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

NSString* const kFlyerInfoViewReuseIdentifier = @"FlyerInfoView";
static const float kBorderWidth = 6.0f;
static const float kCircleBorderWidth = 2.0f;
static const float kBorderCornerRadius = 8.0f;

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
        [self.nibContentView setBackgroundColor:[GameColors bgColorFlyersWithAlpha:1.0f]];
        [self.closeCircle setBorderWidth:kCircleBorderWidth];
        [self.closeCircle setBorderColor:[GameColors bubbleColorFlyersWithAlpha:1.0f]];
        [self.closeCircle setBackgroundColor:[GameColors bgColorFlyersWithAlpha:1.0f]];
        [self.nibTitleView setBackgroundColor:[GameColors bubbleColorFlyersWithAlpha:1.0f]];

        [self addSubview:self.nibView];
        [self setBackgroundColor:[UIColor clearColor]];
        
        _flyer = nil;
    }
    return self;
}

- (void) addButtonTarget:(id)target
{
    if([target respondsToSelector:@selector(handleModalClose:)])
    {
        [self.closeCircle setButtonTarget:target action:@selector(handleModalClose:)];
    }
}

- (void) refreshViewForFlyer:(Flyer *)flyer
{
    _flyer = flyer;
    FlyerType* flyerType = [[FlyerTypes getInstance] getFlyerTypeAtIndex:[flyer flyerTypeIndex]];

    // image
    NSString* flyerTypeName = [flyerType sideimg];
    NSString* imageName = [[FlyerLabFactory getInstance] sideImageForFlyerTypeNamed:flyerTypeName tier:[flyer curUpgradeTier] colorIndex:[flyer curColor]];
    UIImage* image = [[ImageManager getInstance] getImage:imageName];
    [self.imageView setImage:image];

    // trade item info
    NSString* itemImagePath = @"checkerboard.png";
    NSString* itemId = [flyer.inventory itemId];
    if(!itemId)
    {
        itemId = [flyer.inventory orderItemId];
    }
    TradeItemType* itemType = [[TradeItemTypes getInstance] getItemTypeForId:itemId];
    NSString* itemName = nil;
    if(itemType)
    {
        itemImagePath = [itemType imgPath];
        itemName = [itemType name];
    }
    
    // item image
    UIImage* itemImage = [[ImageManager getInstance] getImage:itemImagePath];
    [self.itemImageView setImage:itemImage];
    [self.itemNameLabel setText:itemName];
    
    // num items
    unsigned int numItems = [flyer.inventory orderNumItems] + [flyer.inventory numItems];
    NSString* numText = [PogUIUtility commaSeparatedStringFromUnsignedInt:numItems];
    [self.itemNumLabel setText:[NSString stringWithFormat:@"x%@",numText]];

    // capacity
    FlyerUpgradePack* curPack = [[FlyerLabFactory getInstance] upgradeForTier:[flyer curUpgradeTier]];
    unsigned int cap = [flyerType capacity] * [curPack capacityFactor];
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
    [self.flyerStateLabel setText:[flyer displayNameOfFlyerState]];
    
    // time till dest
    [self.timeTillDestLabel setText:[PogUIUtility stringFromTimeInterval:[flyer timeTillDest]]];
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
    if(_flyer)
    {
        [_flyer removeObserver:self forKeyPath:kKeyFlyerMetersToDest];
        _flyer = nil;
    }
}

@end
