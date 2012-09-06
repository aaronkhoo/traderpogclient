//
//  HiAccuracyLocator.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 5/11/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "HiAccuracyLocatorDelegate.h"
extern NSString* const kUserLocated;
extern NSString* const kUserLocationDenied;

@interface HiAccuracyLocator : NSObject<CLLocationManagerDelegate, UIAlertViewDelegate>
{
    CLLocation* _bestLocation;
}
@property (nonatomic,strong) CLLocation* bestLocation;
@property (nonatomic,weak) NSObject<HiAccuracyLocatorDelegate>* delegate;
           
- (id) initWithAccuracy:(CLLocationAccuracy)accuracy;
- (void) startUpdatingLocation;

@end
