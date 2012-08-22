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

static NSString* const kTradePost_CreateNewPost = @"CreateNewPost";

@class TradeItemType;
@class TradePostAnnotation;
@interface TradePost : NSObject<MKAnnotation, MapAnnotationProtocol>
{
    NSString*   _postId;
    CLLocationCoordinate2D _coord;
    NSString*   _itemId;
    NSString*   _imgPath;
    NSInteger   _supplyMaxLevel;
    NSInteger   _supplyRateLevel;
    NSDate*     _beacontime;
    
    BOOL        _isOwnPost;
    BOOL        _isNPCPost;
    
    // transient variables (not saved; reconstructed after load)
    __weak TradePostAnnotation* _annotation;
    unsigned int _supplyLevel;
    
    // Delegate for callbacks to inform interested parties of completion
    __weak NSObject<HttpCallbackDelegate>* _delegate;
}
@property (nonatomic) NSString* postId;
@property (nonatomic) CLLocationCoordinate2D coord;
@property (nonatomic) NSString* itemId;
@property (nonatomic,weak) TradePostAnnotation* annotation;
@property (nonatomic,readonly) NSInteger supplyMaxLevel;
@property (nonatomic) unsigned int supplyLevel;
@property (nonatomic) BOOL isOwnPost;
@property (nonatomic) BOOL isNPCPost;
@property (nonatomic,readonly) NSString* imgPath;
@property (nonatomic,strong) NSDate* beacontime;
@property (nonatomic,weak) NSObject<HttpCallbackDelegate>* delegate;

- (id) initWithPostId:(NSString*)postId
           coordinate:(CLLocationCoordinate2D)coordinate 
             itemType:(TradeItemType *)itemType
            supplyLevel:(unsigned int)supply;
- (id) initWithCoordinates:(CLLocationCoordinate2D)coordinate 
                           itemType:(TradeItemType *)itemType;
- (void) createNewPostOnServer;
- (id) initWithDictionary:(NSDictionary*)dict;
- (void) setBeacon;
- (bool) beaconActive;

// trade
- (void) deductNumItems:(unsigned int)num;

@end
