//
//  GameEventView.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 9/29/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

extern const float kGameEventViewVisibleSecs;

@class GameEvent;
@class MapControl;
@interface GameEventView : UIView

- (void) refreshWithGameEvent:(GameEvent*)gameEvent targetMap:(MapControl*)map;
@end
