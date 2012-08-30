//
//  BrowsePan.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/29/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "BrowsePan.h"
#import "MapControl.h"
#import "BrowseArea.h"

static const float kBrowsePanBufferMeters = 75.0f;
static const float kBrowsePanSnapBufferMeters = 15.0f;
static const float kBrowsePanSnapDuration = 0.2f;
static const NSTimeInterval kBrowsePanEndingDuration = 1.1;

@interface BrowsePan ()
{
    BOOL _regionSetInCode;
    NSDate* _panEndTime;
}
- (BOOL) enforceBrowseAreaWithBufferMeters:(float)bufferMeters snapDuration:(float)snapDuration;
@end

@implementation BrowsePan
@synthesize map = _map;
@synthesize browseArea = _browseArea;

- (id) initWithMap:(MapControl *)targetMap browseArea:(BrowseArea *)targetBrowseArea
{
    self = [super init];
    if(self)
    {
        _map = targetMap;
        _browseArea = targetBrowseArea;
        _regionSetInCode = NO;
        _panEndTime = nil;
    }
    return self;
}

- (void) handleGesture:(UIGestureRecognizer *)gestureRecognizer
{
    if(UIGestureRecognizerStateBegan == [gestureRecognizer state])
    {
        NSLog(@"BEGAN");
        _panEndTime = nil;
    }
    else if(UIGestureRecognizerStateChanged == [gestureRecognizer state])
    {
        NSLog(@"CHANGED");
        [self enforceBrowseAreaWithBufferMeters:kBrowsePanBufferMeters snapDuration:kBrowsePanSnapDuration];
    }
    else if(UIGestureRecognizerStateEnded == [gestureRecognizer state])
    {
        NSLog(@"ENDED");
        _panEndTime = [NSDate date];
        [self enforceBrowseAreaWithBufferMeters:kBrowsePanBufferMeters snapDuration:kBrowsePanSnapDuration];
    }
}

- (BOOL) isPanEnding
{
    BOOL result = NO;
    if(_panEndTime)
    {
        NSTimeInterval elapsed = -[_panEndTime timeIntervalSinceNow];
        NSLog(@"elapsed is %f", elapsed);
        if(elapsed < kBrowsePanEndingDuration)
        {
            result = YES;
        }
    }
    return result;
}

- (BOOL) enforceBrowseArea
{
    BOOL enforced = [self enforceBrowseAreaWithBufferMeters:kBrowsePanBufferMeters snapDuration:kBrowsePanSnapDuration];
    return enforced;
}

#pragma mark - internal
- (BOOL) enforceBrowseAreaWithBufferMeters:(float)bufferMeters snapDuration:(float)snapDuration
{
    BOOL enforced = NO;
    if([self browseArea] && !_regionSetInCode)
    {
        // enforce bounds
        CLLocationCoordinate2D curCenter = [self.map.view centerCoordinate];
        CLLocationCoordinate2D snapCoord = curCenter;
        //NSLog(@"curCenter (%f, %f); browse center (%f, %f)", curCenter.latitude, curCenter.longitude,
        //      self.browseArea.center.coordinate.latitude, self.browseArea.center.coordinate.longitude);
        if(![self.browseArea isInBounds:curCenter withBufferMeters:bufferMeters])
        {
            snapCoord = [self.browseArea snapCoord:curCenter withBufferMeters:kBrowsePanSnapBufferMeters];
            [self.map.view setCenterCoordinate:snapCoord animated:YES];
            NSLog(@"rubberband started");
            self.map.view.scrollEnabled = NO;
            _regionSetInCode = YES;
            enforced = YES;
            dispatch_time_t scrollLockTimeout = dispatch_time(DISPATCH_TIME_NOW, snapDuration * NSEC_PER_SEC);
            dispatch_after(scrollLockTimeout, dispatch_get_main_queue(), ^(void){
                // unset set-from-code after a delay to prevent rapid re-entrants
                self.map.view.scrollEnabled = YES;
                _regionSetInCode = NO;
                [self.map.view setCenterCoordinate:snapCoord animated:YES];
                NSLog(@"rubberband done");
            });
        }
    }
    return enforced;
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

@end
