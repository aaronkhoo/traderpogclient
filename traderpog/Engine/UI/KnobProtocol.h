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
- (void) didPressKnobAtIndex:(unsigned int)index;
- (unsigned int) numItemsInKnob:(KnobControl*)knob;
- (NSString*) knob:(KnobControl*)knob titleAtIndex:(unsigned int)index;
@end

