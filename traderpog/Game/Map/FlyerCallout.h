//
//  FlyerCallout.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/13/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "MapProtocols.h"

@class Flyer;
@interface FlyerCallout : NSObject<MKAnnotation,MapAnnotationProtocol>
{
    CLLocationCoordinate2D _coord;
    __weak Flyer* _flyer;
}
@property (nonatomic,weak) Flyer* flyer;
@property (nonatomic,weak) MKAnnotationView* parentAnnotationView;
- (id) initWithFlyer:(Flyer*)flyer;
@end
