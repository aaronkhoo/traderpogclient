//
//  BrowsePinch.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/29/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "BrowsePinch.h"
#import "MapControl.h"
#import "BrowseArea.h"
#import "MKMapView+ZoomLevel.h"

static const float kBrowsePanBufferMeters = 75.0f;
static const float kBrowsePanSnapBufferMeters = 15.0f;
static const float kBrowsePanSnapDuration = 0.2f;

@interface BrowsePinch ()
{
    BOOL _regionSetInCode;
}
- (BOOL) enforceBrowseAreaWithBufferMeters:(float)bufferMeters snapDuration:(float)snapDuration;
@end

@implementation BrowsePinch
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
    }
    return self;
}

- (void) handleGesture:(UIGestureRecognizer *)gestureRecognizer
{
    if(UIGestureRecognizerStateBegan == [gestureRecognizer state])
    {
    }
    else if(UIGestureRecognizerStateChanged == [gestureRecognizer state])
    {
        [self enforceBrowseAreaWithBufferMeters:kBrowsePanBufferMeters snapDuration:kBrowsePanSnapDuration];
    }
    else if(UIGestureRecognizerStateEnded == [gestureRecognizer state])
    {
        [self enforceBrowseAreaWithBufferMeters:kBrowsePanBufferMeters snapDuration:kBrowsePanSnapDuration];
    }
}

#pragma mark - internal
- (BOOL) enforceBrowseAreaWithBufferMeters:(float)bufferMeters snapDuration:(float)snapDuration
{
    BOOL enforced = NO;
    if([self browseArea] && !_regionSetInCode)
    {
        double fMinZoom = (double)[self.browseArea minZoom];
        double fZoomLevel = [self.map.view fZoomLevel];
        if((fZoomLevel+1) < fMinZoom)
        {
            // enforce bounds
            CLLocationCoordinate2D curCenter = [self.map.view centerCoordinate];
            CLLocationCoordinate2D snapCoord = curCenter;
            if(![self.browseArea isInBounds:curCenter withBufferMeters:bufferMeters])
            {
                snapCoord = [self.browseArea snapCoord:curCenter];
            }
            [self.map.view setCenterCoordinate:snapCoord zoomLevel:[self.browseArea minZoom] animated:YES];
            NSLog(@"pinch rubberband started");
            _regionSetInCode = YES;
            self.map.view.zoomEnabled = NO;
            enforced = YES;
            dispatch_time_t scrollLockTimeout = dispatch_time(DISPATCH_TIME_NOW, kBrowsePanSnapDuration * NSEC_PER_SEC);
            dispatch_after(scrollLockTimeout, dispatch_get_main_queue(), ^(void){
                _regionSetInCode = NO;
                self.map.view.zoomEnabled = YES;
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
