//
//  WheelProtocol.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 6/13/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WheelBubble;
@class WheelControl;
@protocol WheelProtocol <NSObject>
- (void) wheelDidMoveTo:(unsigned int)index;
- (void) wheelDidSelect:(unsigned int)index;
@end

@protocol WheelDataSource <NSObject>
- (unsigned int) numItemsInWheel:(WheelControl*)wheel;
- (WheelBubble*) wheel:(WheelControl*)wheel bubbleAtIndex:(unsigned int)index;
@end
