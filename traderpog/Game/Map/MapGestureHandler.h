//
//  MapGestureHandler.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/4/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MapControl;

@interface MapGestureHandler : NSObject<UIGestureRecognizerDelegate>

@property (weak, nonatomic) MapControl* targetMap;

- (id) initWithMap:(MapControl*)map;
- (void) handlePanGesture:(UIGestureRecognizer*)recognizer;

@end
