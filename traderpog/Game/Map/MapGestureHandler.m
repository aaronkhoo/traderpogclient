//
//  MapGestureHandler.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/4/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "MapGestureHandler.h"
#import "MapControl.h"

@implementation MapGestureHandler

- (id) initWithMap:(MapControl *)map
{
    self = [super init];
    if(self)
    {
        self.targetMap = map;
    }
    return self;
}

#pragma mark - gesture handlers

- (void) handlePanGesture:(UIGestureRecognizer*)recognizer
{
    if(UIGestureRecognizerStateBegan == [recognizer state])
    {
        // deselect all annotations when gesture begins to clear the map of any
        // callouts and modals
        [_targetMap deselectAllAnnotations];
    }
    else if(UIGestureRecognizerStateChanged == [recognizer state])
    {
    }
    else if(UIGestureRecognizerStateEnded == [recognizer state])
    {
    }
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}


@end
