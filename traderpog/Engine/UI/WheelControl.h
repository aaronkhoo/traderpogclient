//
//  WheelControl.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 6/13/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WheelProtocol.h"

@class WheelBubble;
@interface WheelControl : UIControl
{
    __weak id<WheelProtocol>    _delegate;
    __weak id<PogWheelDataSource>  _dataSource;
    UIView*                 _centerCircle;
    UIView*                 _container;
    unsigned int            _numSlices;
    NSMutableArray*         _reuseQueue;    // WheelBubble
    NSMutableArray*         _activeQueue;   // WheelBubble
}
@property (nonatomic,weak) id<WheelProtocol> delegate;
@property (nonatomic,weak) id<PogWheelDataSource> dataSource;
@property (nonatomic,strong) UIView* container;
@property (nonatomic) unsigned int numSlices;

- (id)initWithFrame:(CGRect)frame 
           delegate:(id)delegate 
         dataSource:(id)dataSource 
          numSlices:(unsigned int)numSlices;
- (void) initBeaconSlots;
- (void) queueForReuse:(WheelBubble*)bubble;
- (WheelBubble*) dequeueResuableBubble;

- (void) showWheelAnimated:(BOOL)isAnimated withDelay:(float)delay;
- (void) hideWheelAnimated:(BOOL)isAnimated withDelay:(float)delay;
- (BOOL) isWheelStateHidden;
@end
