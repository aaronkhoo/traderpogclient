//
//  HiAccuracyLocator.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 5/11/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "HiAccuracyLocator.h"
#import "CLLocation+Pog.h"

typedef enum 
{
    kStopReasonDesiredAccuracy = 0,
    kStopReasonTimedOut,
    kStopReasonLocationUnknown,
    kStopReasonDenied,
    
    kStopReasonNum
} StopReason;

NSString* const kUserLocated = @"UserLocated";
NSString* const kUserLocationDenied = @"UserLocationDenied";

static NSTimeInterval kLocationUpdateTimeout = 6.0;

@interface HiAccuracyLocator ()
{
    CLLocationManager* _locationManager;
    BOOL        _isLocating;
    NSDate*     _startTimestamp;
}

- (void) updatingLocationTimedOut;
- (void) stopUpdatingLocation:(StopReason)reason;
@end

@implementation HiAccuracyLocator
@synthesize bestLocation = _bestLocation;
@synthesize delegate;

- (id) init
{
    self = [super init];
    if(self)
    {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        _bestLocation = nil;
        _isLocating = NO;
        _startTimestamp = [NSDate date];
        self.delegate = nil;
    }
    return self;
}


#pragma mark - controls
- (void) startUpdatingLocation
{
    [self performSelector:@selector(updatingLocationTimedOut) withObject:nil afterDelay:kLocationUpdateTimeout];
    [_locationManager startUpdatingLocation];
    _startTimestamp = [NSDate date];
    _bestLocation = nil;
    _isLocating = YES;
}

- (void) updatingLocationTimedOut
{
    if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined)
    {
        // if user not yet determined authorization, renew the timeout
        [self performSelector:@selector(updatingLocationTimedOut) withObject:nil afterDelay:kLocationUpdateTimeout];
    }
    else 
    {
        // otherwise, just timeout
        [self stopUpdatingLocation:kStopReasonTimedOut];
    }
}

- (void) stopUpdatingLocation:(StopReason)reason
{
    if(_isLocating)
    {
        [_locationManager stopUpdatingLocation];
        switch (reason) 
        {
            case kStopReasonDesiredAccuracy:
                [[NSNotificationCenter defaultCenter] postNotificationName:kUserLocated object:self];
                if([self delegate])
                {
                    [self.delegate locator:self didLocateUser:YES];
                }
                break;
                
            case kStopReasonLocationUnknown:
                NSLog(@"location unknown");
                if(nil == [self bestLocation])
                {
                    // if timed-out and no location, default the Penang 
                    self.bestLocation = [CLLocation penang];
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:kUserLocated object:self];
                if([self delegate])
                {
                    [self.delegate locator:self didLocateUser:NO];
                }
                
            case kStopReasonTimedOut:
            {
                NSLog(@"location timed out");
                BOOL hasRealLocation = YES;
                if(nil == [self bestLocation])
                {
                    // if timed-out and no location, default the Penang 
                    self.bestLocation = [CLLocation penang];
                    hasRealLocation = NO;
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:kUserLocated object:self];
                if([self delegate])
                {
                    [self.delegate locator:self didLocateUser:hasRealLocation];
                }
            }
                break;
                
            case kStopReasonDenied:
            {
                // show alert
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Location Service Required" 
                                                                message:@"Please enable Location Service in Settings"
                                                               delegate:self 
                                                      cancelButtonTitle:@"Ok" 
                                                      otherButtonTitles:nil];
                [alert show];
            }
                break;

            default:
                // do nothing
                break;
        }
        
        _isLocating = NO;
    }
}

#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation 
{
    if(_isLocating)
    {
        // test the age of the location measurement to determine if the measurement is cached
        // in most cases you will not want to rely on cached measurements
        NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
        NSTimeInterval bestAge = -[_startTimestamp timeIntervalSinceNow];
        if([self bestLocation])
        {
            bestAge = -[self.bestLocation.timestamp timeIntervalSinceNow];
        }
        
        if (locationAge <= bestAge)
        {
            // test that the horizontal accuracy does not indicate an invalid measurement
            if (newLocation.horizontalAccuracy > 0)
            {
                // test the measurement to see if it is more accurate than the previous measurement
                NSTimeInterval bestLocationAge = -[self.bestLocation.timestamp timeIntervalSinceNow];
                if ([self bestLocation] == nil || self.bestLocation.horizontalAccuracy > newLocation.horizontalAccuracy ||
                    (bestLocationAge > locationAge))
                {
                    // store best location
                    self.bestLocation = newLocation;

                    // test the measurement to see if it meets the desired accuracy
                    if (newLocation.horizontalAccuracy <= _locationManager.desiredAccuracy) 
                    {
                        // we can also cancel our previous performSelector:withObject:afterDelay: - it's no longer necessary
                        [NSObject cancelPreviousPerformRequestsWithTarget:self 
                                                                 selector:@selector(updatingLocationTimedOut) 
                                                                   object:nil];
                        // we have a measurement that meets our requirements, so we can stop updating the location
                        [self stopUpdatingLocation:kStopReasonDesiredAccuracy];
                    }
                }
            }
        }
    }
}


- (void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    switch([error code])
    {            
        case kCLErrorDenied:
            [self stopUpdatingLocation:kStopReasonDenied];
            break;
            
        default:
        case kCLErrorLocationUnknown:
            [self stopUpdatingLocation:kStopReasonLocationUnknown];
            break;
    }
}

#pragma mark - UIAlertViewDelegate

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kUserLocationDenied object:self];
    if([self delegate])
    {
        [self.delegate locator:self didLocateUser:NO];
    }
}


@end
