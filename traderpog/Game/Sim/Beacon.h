//
//  Beacon.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MapProtocols.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MKAnnotation.h>

@interface Beacon : NSObject<MKAnnotation, MapAnnotationProtocol>
{
    NSString* _beaconId;
    NSString* _postId;

    // transient variables
    CLLocationCoordinate2D _coord;
}
@property (nonatomic,readonly) NSString* beaconId;
@property (nonatomic,readonly) NSString* postId;
@property (nonatomic) CLLocationCoordinate2D coord;

- (id) initWithBeaconId:(NSString*)beaconId postId:(NSString *)postId;
@end
