//
//  HiAccuracyLocator.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 5/11/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

extern NSString* const kUserLocated;
extern NSString* const kUserLocationDenied;

@interface HiAccuracyLocator : NSObject<CLLocationManagerDelegate, UIAlertViewDelegate>
{
    CLLocation* _bestLocation;
}
@property (nonatomic,retain) CLLocation* bestLocation;

- (void) startUpdatingLocation;

@end
