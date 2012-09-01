//
//  ForeignTradePost.m
//  traderpog
//
//  Created by Aaron Khoo on 8/31/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "AsyncHttpCallMgr.h"
#import "ForeignTradePost.h"
#import "ImageManager.h"
#import "MathUtils.h"
#import "TradeItemType.h"
#import "TradeItemTypes.h"

@implementation ForeignTradePost

#pragma mark - public functions
- (id) initWithDictionary:(NSDictionary*)dict
{
    self = [super initWithDictionary:dict];
    if (self)
    {
        // These two only matter in the context of a foreign beacon trade post
        _userId = [NSString stringWithFormat:@"%d", [[dict valueForKeyPath:kKeyTradeUserId] integerValue]];
        _fbId = [NSString stringWithFormat:@"%@", [dict valueForKeyPath:kKeyTradeFBId]];
        
        _supplyLevel = [self getForeignSupplyLevel];
    }
    return self;
}

- (void)updatePostSupply:(NSInteger)deductSupplies
{
    NSString *path = [NSString stringWithFormat:@"posts/%@", _postId];
    NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithInteger:deductSupplies], kKeyTradeSupply,
                                nil];
    NSString* msg = [[NSString alloc] initWithFormat:@"Updating Foreign Post with %d supply change failed", deductSupplies];
    
    [[AsyncHttpCallMgr getInstance] newAsyncHttpCall:path
                                      current_params:parameters
                                     current_headers:nil
                                         current_msg:msg
                                        current_type:putType];
}

- (void) deductNumItems:(unsigned int)num
{
    // For foreign posts, rather than deduct, just randomly reassign a new value
    self.supplyLevel = [self getForeignSupplyLevel];
    
    // Update the foreign post with the amount of supplies reduced
    [self updatePostSupply:-num];
}

#pragma mark - private functions

- (unsigned int) getForeignSupplyLevel
{
    // Foreign trade posts always have items to trade with
    TradeItemType* itemType = [[TradeItemTypes getInstance] getItemTypeForId:_itemId];
    unsigned int maxSupply = MAX(1, (_supplyMaxLevel - 1) * [itemType multiplier]) * [itemType supplymax];
    // Generate a random supply level roughly between 10 - 100% of allowable max supply
    return MIN(MAX(0.2f, RandomFrac()) * maxSupply, maxSupply);
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
                                                fallbackNamed:@"b_homebase.png"];
    [annotationView.imageView setImage:image];
    
    return annotationView;
}

@end
