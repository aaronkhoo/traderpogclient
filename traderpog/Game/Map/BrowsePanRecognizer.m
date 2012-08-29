//
//  BrowsePanRecognizer.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/29/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "BrowsePanRecognizer.h"

#import "BrowseArea.h"
#import "MapControl.h"
#import <MapKit/MapKit.h>

static const float kBrowsePanBufferMeters = 150.0f;
static const float kBrowsePanSnapBufferMeters = 25.0f;
static const float kBrowsePanSnapDuration = 0.2f;

@interface BrowsePanRecognizer ()
{
    BOOL _regionSetInCode;
}
- (void) handleGesture:(UIGestureRecognizer*)gestureRecognizer;
- (BOOL) enforceBrowseAreaWithBufferMeters:(float)bufferMeters snapDuration:(float)snapDuration;
@end

@implementation BrowsePanRecognizer
@synthesize map = _map;
@synthesize browseArea = _browseArea;

- (id) initWithMap:(MapControl *)targetMap browseArea:(BrowseArea *)targetBrowseArea
{
    self = [super initWithTarget:self action:@selector(handleGesture:)];
    if(self)
    {
        _map = targetMap;
        _browseArea = targetBrowseArea;
        _regionSetInCode = NO;
        self.delegate = self;
    }
    return self;
}

- (void) reset
{
    [super reset];
}

- (void) touchesBegan:(NSSet*)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    if([self enforceBrowseAreaWithBufferMeters:kBrowsePanBufferMeters snapDuration:kBrowsePanSnapDuration])
    {
        // if enforced, end this gesture
        self.state = UIGestureRecognizerStateRecognized;
        NSLog(@"set to Recognized");
    }
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    NSLog(@"touch ended");
    [self enforceBrowseAreaWithBufferMeters:0.0f snapDuration:kBrowsePanSnapDuration];
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    NSLog(@"touch canceled");
    [self enforceBrowseAreaWithBufferMeters:0.0f snapDuration:kBrowsePanSnapDuration];
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

- (void) handleGesture:(UIGestureRecognizer *)gestureRecognizer
{
    // do nothing
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}


@end
