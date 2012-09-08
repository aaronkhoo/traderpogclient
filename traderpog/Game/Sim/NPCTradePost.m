//
//  NPCTradePost.m
//  traderpog
//
//  Created by Aaron Khoo on 8/31/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "ImageManager.h"
#import "MathUtils.h"
#import "NPCTradePost.h"
#import "TradeItemType.h"
#import "TradeItemTypes.h"

@implementation NPCTradePost

#pragma mark - Public functions

- (id) initWithPostId:(NSString*)postId
           coordinate:(CLLocationCoordinate2D)coordinate
                bucks:(unsigned int)bucks
{
    self = [super init];
    if(self)
    {
        NSArray* itemTypes = [[TradeItemTypes getInstance] getItemTypesForTier:kTradeItemTierMin];
        int randItemIndex = RandomWithinRange(0, [itemTypes count]-1);
        TradeItemType* itemType = [itemTypes objectAtIndex:randItemIndex];
        unsigned int supply = [self generateSupplyLevel:itemType playerBucks:bucks];
        
        _postId = postId;
        _coord = coordinate;
        if(itemType)
        {
            _itemId = [itemType itemId];
            _supplyLevel = MIN([itemType supplymax], supply);
            _supplyMaxLevel = [itemType supplymax];
            _supplyRateLevel = [itemType supplyrate];
        }
        else
        {
            // if itemType is null, make this a dummy post with 0 supply
            _itemId = nil;
            _supplyLevel = 0;
            _supplyMaxLevel = 0;
            _supplyRateLevel = 0;
        }
        _annotation = nil;
        
        _hasFlyer = NO;
    }
    return self;
}

#pragma mark - private functions
-(unsigned int) generateSupplyLevel:(TradeItemType*)itemType playerBucks:(unsigned int)playerBucks
{
    // This function is used to generate a supply level for NPC posts
    float randPriceFactor = MAX(0.2f,0.7f - (RandomFrac() * 0.5f));
    return (playerBucks / [itemType price]) * randPriceFactor;
}

#pragma mark - MapAnnotationProtocol
- (MKAnnotationView*) annotationViewInMap:(MKMapView *)mapView
{
    TradePostAnnotationView* annotationView = [super getAnnotationViewInstance:mapView];
    
    if([self hasFlyer])
    {
        annotationView.enabled = NO;
    }
    else
    {
        annotationView.enabled = YES;
    }
    
    UIImage* image = [[ImageManager getInstance] getImage:[self imgPath]
                                            fallbackNamed:@"b_tradepost.png"];
    [annotationView.imageView setImage:image];
    
    return annotationView;
}

@end