//
//  TradePost.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface TradePost : NSObject<NSCoding>
{
    CLLocationCoordinate2D _coord;
}
@property (nonatomic) CLLocationCoordinate2D coord;
- (id) initWithCoordinate:(CLLocationCoordinate2D)coordinate;
@end
