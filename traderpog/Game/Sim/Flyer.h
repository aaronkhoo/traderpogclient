//
//  Flyer.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/21/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class TradePost;
@class FlightPathOverlay;
@class FlyerAnnotation;
@interface Flyer : NSObject
{
    float     _flightSpeed;
    NSString* _curPostId;
    NSString* _nextPostId;

    // transient variables (not saved; reconstructed after load)
    __weak FlyerAnnotation* _annotation;
    CLLocationCoordinate2D _coord;
    FlightPathOverlay* _flightPathRender;
}
@property (nonatomic) float flightSpeed;
@property (nonatomic,strong) NSString* curPostId;
@property (nonatomic,strong) NSString* nextPostId;
@property (nonatomic,strong) FlightPathOverlay* flightPathRender;
@property (nonatomic,weak) FlyerAnnotation* annotation;
@property (nonatomic) CLLocationCoordinate2D coord;

- (id) initAtPost:(TradePost*)tradePost;
- (void) departForPostId:(NSString*)postId;
- (void) updateAtDate:(NSDate*)currentTime;

@end
