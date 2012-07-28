//
//  KnobDelegate.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/28/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KnobControl;
@protocol KnobDelegate <NSObject>

- (unsigned int) numSlicesOnKnob:(KnobControl*)knob;
- (unsigned int) numItemsOnKnob:(KnobControl*)knob;
- (NSString*) knob:(KnobControl*)knob itemAtIndex:(unsigned int)index;

@end
