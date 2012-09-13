//
//  TradePost.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MKAnnotation.h>
#import "HttpCallbackDelegate.h"
#import "MapProtocols.h"
#import "TradePostAnnotationView.h"

static NSString* const kTradePost_CreateNewPost = @"CreateNewPost";

@class Flyer;
@class TradeItemType;
@interface TradePost : NSObject<MKAnnotation, MapAnnotationProtocol>
{
    NSString*   _postId;
    CLLocationCoordinate2D _coord;
    NSString*   _itemId;
    NSString*   _imgPath;
    NSInteger   _supplyMaxLevel;
    NSInteger   _supplyRateLevel;
    
    // transient variables (not saved; reconstructed after load)
    unsigned int _supplyLevel;
    __weak Flyer*      _flyerAtPost;
    
    // Delegate for callbacks to inform interested parties of completion
    __weak NSObject<HttpCallbackDelegate>* _delegate;
}
@property (nonatomic) NSString* postId;
@property (nonatomic) CLLocationCoordinate2D coord;
@property (nonatomic) NSString* itemId;
@property (nonatomic,readonly) NSInteger supplyMaxLevel;
@property (nonatomic) unsigned int supplyLevel;
@property (nonatomic,readonly) NSString* imgPath;
@property (nonatomic,strong) NSDate* beacontime;
@property (nonatomic,weak) Flyer* flyerAtPost;
@property (nonatomic,weak) NSObject<HttpCallbackDelegate>* delegate;

- (void) deductNumItems:(unsigned int)num;
- (TradePostAnnotationView*) getAnnotationViewInstance:(MKMapView *)mapView;

@end
