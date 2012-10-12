//
//  ItemBubble.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/2/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "ItemBubble.h"
#import "PogUIUtility.h"

static const float kItemBubbleImageYOffset = -0.1f;
static const float kItemBubbleImageSize = 0.7f; // fraction of bubble width
static const float kItemLabelHeight = 15.0f;
static const float kItemLabelYOffset = 0.85f;

@implementation ItemBubble

- (id)initWithFrame:(CGRect)frame
{
    NSAssert(false, @"must use initWithFrame:borderWidth:color:borderColor to init itemBubble");
    return nil;    
}

- (id) initWithFrame:(CGRect)frame borderWidth:(float)borderWidth color:(UIColor*)color borderColor:(UIColor*)borderColor
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // create a background view so that we can make it semi-transparent
        self.backgroundView = [[UIView alloc] initWithFrame:self.bounds];
        [self.backgroundView setBackgroundColor:color];
        [self addSubview:self.backgroundView];
        
        // place image in the center of the bubble
        float imageWidth = kItemBubbleImageSize * self.bounds.size.width;
        CGRect imageFrame = [PogUIUtility createCenterFrameWithSize:CGSizeMake(imageWidth, imageWidth)
                                                            inFrame:self.bounds];
        imageFrame.origin.y += (kItemBubbleImageYOffset * imageFrame.size.height);
        self.imageView = [[UIImageView alloc] initWithFrame:imageFrame];
        [self addSubview:self.imageView];
        
        // place label underneath the image
        CGRect labelRect = CGRectMake(imageFrame.origin.x, imageFrame.origin.y + (imageFrame.size.height * kItemLabelYOffset),
                                      imageFrame.size.width,kItemLabelHeight);
        self.itemLabel = [[UILabel alloc] initWithFrame:labelRect];
        [self.itemLabel setTextAlignment:UITextAlignmentCenter];
        [self.itemLabel setFont:[UIFont fontWithName:@"Marker Felt" size:15.0f]];
        [self.itemLabel setAdjustsFontSizeToFitWidth:YES];
        [self.itemLabel setTextColor:[UIColor whiteColor]];
        [self.itemLabel setBackgroundColor:[UIColor clearColor]];
        [self addSubview:self.itemLabel];
        
        [PogUIUtility setCircleForView:self withBorderWidth:borderWidth borderColor:borderColor];
        [self setBackgroundColor:[UIColor clearColor]];
    }
    return self;
}

@end
