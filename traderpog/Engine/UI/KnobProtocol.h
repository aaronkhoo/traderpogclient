//
//  KnobProtocol.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/6/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KnobControl;
@protocol KnobProtocol <NSObject>
//- (void) wheelDidMoveTo:(unsigned int)index;
//- (void) wheelDidSelect:(unsigned int)index;
- (void) didPressKnobCenter;
@end

@protocol KnobDataSource <NSObject>
- (unsigned int) numItemsInWheel:(KnobControl*)knob;
- (UIView*) knob:(KnobControl*)knob viewAtIndex:(unsigned int)index;
@end
