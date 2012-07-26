//
//  Flyer.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/21/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HttpCallbackDelegate.h"
#import <CoreLocation/CoreLocation.h>

static NSString* const kFlyer_CreateNewFlyer = @"Flyer_CreateNewFlyer";

@class TradePost;
@class FlightPathOverlay;
@class FlyerAnnotation;
@interface Flyer : NSObject
{
    NSString* _flyerId;
    float     _flightSpeed;
    NSString* _curPostId;
    NSString* _nextPostId;

    // transient variables (not saved; reconstructed after load)
    __weak FlyerAnnotation* _annotation;
    CLLocationCoordinate2D _coord;
    FlightPathOverlay* _flightPathRender;
    CGAffineTransform _transform;
    
    // Delegate for callbacks to inform interested parties of completion
    __weak NSObject<HttpCallbackDelegate>* _delegate;
}
@property (nonatomic) NSString* flyerId;
@property (nonatomic) float flightSpeed;
@property (nonatomic,strong) NSString* curPostId;
@property (nonatomic,strong) NSString* nextPostId;
@property (nonatomic,strong) FlightPathOverlay* flightPathRender;
@property (nonatomic,weak) FlyerAnnotation* annotation;
@property (nonatomic) CLLocationCoordinate2D coord;
@property (nonatomic,readonly) CGAffineTransform transform;
@property (nonatomic,weak) NSObject<HttpCallbackDelegate>* delegate;

- (id) initAtPost:(TradePost*)tradePost;
- (id) initWithPostAndFlyerId:(TradePost*)tradePost, NSString* flyerId;
- (void) createNewUserFlyerOnServer;
- (void) departForPostId:(NSString*)postId;
- (void) updateAtDate:(NSDate*)currentTime;

@end
