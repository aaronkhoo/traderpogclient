//
//  GameEventView.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 9/29/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GameEvent;
@interface GameEventView : UIView

- (void) setPrimaryColor:(UIColor*)color;
- (void) refreshWithGameEvent:(GameEvent*)gameEvent;
@end
