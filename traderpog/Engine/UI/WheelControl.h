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
@class MapControl;
@class LabelCircle;
@interface WheelControl : UIControl
{
    __weak id<WheelProtocol>    _delegate;
    __weak id<WheelDataSource>  _dataSource;
    __weak MapControl*      _superMap;
    UIView*                 _container;
    UIView*                 _wheelView;
    UIView*                 _previewView;
    UIView*                 _previewCircle;
    UIView*                 _previewLabelBg;
    UILabel*                _previewLabel;
    UIImageView*            _previewImageView;
    LabelCircle*            _okView;
    LabelCircle*            _cancelView;
    unsigned int            _numSlices;
    NSMutableArray*         _reuseQueue;    // WheelBubble
    NSMutableArray*         _activeQueue;   // WheelBubble
}
@property (nonatomic,weak) id<WheelProtocol> delegate;
@property (nonatomic,weak) id<WheelDataSource> dataSource;
@property (nonatomic,weak) MapControl* superMap;
@property (nonatomic,strong) UIView* container;
@property (nonatomic,readonly) UIView* previewView;
@property (nonatomic,readonly) UIView* previewCircle;
@property (nonatomic,strong) UIView* previewLabelBg;
@property (nonatomic,strong) UILabel* previewLabel;
@property (nonatomic,readonly) UIImageView* previewImageView;
@property (nonatomic,strong) LabelCircle* okView;
@property (nonatomic,strong) LabelCircle* cancelView;
@property (nonatomic) unsigned int numSlices;

- (id)initWithFrame:(CGRect)frame 
           delegate:(id)delegate 
         dataSource:(id)dataSource
           superMap:(MapControl*)superMap
         wheelFrame:(CGRect)wheelFrame
       previewFrame:(CGRect)previewFrame
          numSlices:(unsigned int)numSlices;
- (void) initBeaconSlots;
- (void) queueForReuse:(WheelBubble*)bubble;
- (WheelBubble*) dequeueResuableBubble;

- (void) showWheelAnimated:(BOOL)isAnimated withDelay:(float)delay;
- (void) hideWheelAnimated:(BOOL)isAnimated withDelay:(float)delay;
- (BOOL) isWheelStateHidden;
- (void) resetWheelToSliceIndex:(unsigned int)resetIndex;
- (void) disableYesButton;
- (void) enableYesButton;
@end
