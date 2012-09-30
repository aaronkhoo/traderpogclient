//
//  WheelControl.m
//  traderpog
//
//  Regarding _slices:
//      slices are arranged with their minAngle->maxAngle going in clockwise direction
//      of the wheel; all minAngle is less than maxAngle except for the slice that
//      crosses the sign boundary for even-number-slices wheel;
//      see the slice-selection loop in continueTrackingWithTouch
//
//
//  Created by Shu Chiun Cheah on 6/13/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "WheelControl.h"
#import "WheelSlice.h"
#import "PogUIUtility.h"
#import "WheelBubble.h"
#import "LabelCircle.h"
#import <QuartzCore/QuartzCore.h>

enum kWheelStates
{
    kWheelStateHidden = 0,
    kWheelStateTransitionIn,
    kWheelStateActive,
    kWheelStateTransitionOut,
    
    kWheelStateNum
};
static const float kWheelRenderOffsetFactor = 2.4f; // offset angle is this factor multiplied with sliceWidth
static const float kSliceTouchMaxDistFrac = 0.8f;
static const float kSliceLengthFrac = 0.63f;

@interface WheelControl ()
{
    CGAffineTransform _startTransform;
    float _deltaAngle;
    float _prevAngle;
    unsigned int _prevIndex;
    NSMutableArray* _slices;
    unsigned int _selectedSlice;
    BOOL _springEngaged;
    unsigned int _springTargetIndex;
    float _absAngle;
    float _absStartAngle;
    unsigned int _springBeaconSlot;
    unsigned int _selectedBeacon;
    CGAffineTransform _logicalTransform;    // logical transform used to track the wheel slices
                                            // separately from the rendering transform because
                                            // the wheel is rendered with a one-slice offset so that
                                            // the current selection is one notch above the bottom of the screen
    unsigned int _state;
    CGAffineTransform _pushedWheelTransform;
    CGAffineTransform _hiddenPreviewTransform;
    
    UIView* _previewContent;
    UIButton* _buttonOk;
    UIButton* _buttonClose;
}
@property (nonatomic,retain) NSMutableArray* slices;
@property (nonatomic,assign) unsigned int selectedSlice;
- (void) createWheelRenderWithFrame:(CGRect)wheelFrame;
- (float) distFromCenter:(CGPoint)point;
- (void) buildSlicesEven;
- (void) buildSlicesOdd;
- (float) sliceWidth;
- (void) refreshBeaconSlotsWithSelectedBeacon:(unsigned int)beaconIndex selectedSlice:(unsigned int)sliceIndex;
- (unsigned int) itemIndexAtAngle:(float)absAngle forNumItems:(unsigned int)numItems;
- (float) midAngleAtItemIndex:(unsigned int)index forNumItems:(unsigned int)numItems;
- (float) maxItemMaxAngleForNumItems:(unsigned int)numItems;
- (float) minItemMinAngle;
- (CGAffineTransform) renderTransformFromLogicalTransform:(CGAffineTransform)xform;
- (void) levelContentViewForSlice:(WheelSlice*)slice item:(unsigned int)itemIndex numItems:(unsigned int)numItems;
- (void) levelContentViewForSlice:(WheelSlice*)slice;
- (void) levelContentViewsWithItem:(unsigned int)itemIndex numItems:(unsigned int)numItems;
- (CGAffineTransform) scaleSlice:(WheelSlice*)slice 
                        withItem:(unsigned int)itemIndex 
                    overNumItems:(unsigned int)numItems
                        absAngle:(float)absAng;

- (void) createPreviewCircleWithFrame:(CGRect)previewFrame;
- (void) didOkInPreview:(id)sender;
- (void) didCloseInPreview:(id)sender;

@end

@implementation WheelControl
@synthesize delegate = _delegate;
@synthesize dataSource = _dataSource;
@synthesize superMap = _superMap;
@synthesize container = _container;
@synthesize previewView = _previewView;
@synthesize previewCircle = _previewCircle;
@synthesize numSlices = _numSlices;
@synthesize slices = _slices;
@synthesize selectedSlice = _selectedSlice;
@synthesize previewLabelBg = _previewLabelBg;
@synthesize previewLabel = _previewLabel;
@synthesize previewImageView = _previewImageView;
@synthesize okView = _okView;
@synthesize cancelView = _cancelView;

static const float kHiddenPreviewScale = 0.37f;
static const float kHiddenPreviewXFrac = 0.24f; // fraction of width of preview-frame
static const float kHiddenPreviewYFrac = 0.66f; // fraction of height of preview frame

- (id)initWithFrame:(CGRect)frame
           delegate:(id)delegate 
         dataSource:(id)dataSource
           superMap:(MapControl*)superMap
         wheelFrame:(CGRect)wheelFrame
       previewFrame:(CGRect)previewFrame
          numSlices:(unsigned int)numSlices
{
    self = [super initWithFrame:frame];
    if (self) 
    {
        self.numSlices = numSlices;
        self.delegate = delegate;
        self.dataSource = dataSource;
        self.superMap = superMap;

        // add Preview first
        // previewFrame is given in terms of the superview; so, need to transform
        // it into localframe
        CGRect localPreviewFrame = CGRectMake(previewFrame.origin.x - frame.origin.x,
                                              previewFrame.origin.y - frame.origin.y,
                                              previewFrame.size.width,
                                              previewFrame.size.height);
        [self createPreviewCircleWithFrame:localPreviewFrame];
        
        _reuseQueue = [NSMutableArray arrayWithCapacity:10];
        _activeQueue = [NSMutableArray arrayWithCapacity:10];
        self.selectedSlice = 0;
        _selectedBeacon = 0;
        
        // then add Wheel
        [self createWheelRenderWithFrame:wheelFrame];
        
        _springEngaged = NO;
        _absAngle = 0.0f;
        _pushedWheelTransform = CGAffineTransformIdentity;

        [self initBeaconSlots];
        [self.delegate wheel:self didSettleAt:_selectedBeacon];

        // init hidden preview transform
        CGAffineTransform hiddenPreviewPos = CGAffineTransformMakeTranslation(kHiddenPreviewXFrac* previewFrame.size.width, kHiddenPreviewYFrac * previewFrame.size.height);
        _hiddenPreviewTransform = CGAffineTransformScale(hiddenPreviewPos, kHiddenPreviewScale, kHiddenPreviewScale);
        
        // init wheel to be hidden
        [self hideWheelAnimated:NO withDelay:0.0f];
    }
    return self;
}

- (WheelBubble*) dequeueResuableBubble
{
    WheelBubble* result = nil;
    if([_reuseQueue count])
    {
        result = [_reuseQueue lastObject];
        
        // retain it into the active queue
        [_activeQueue addObject:result];
        
        [_reuseQueue removeLastObject];
    }
    return result;
}

static const int kLabelViewTag = 10;
- (void) queueForReuse:(WheelBubble *)bubble
{
    [_reuseQueue addObject:bubble];
    
    // remove it from the active retention queue
    [_activeQueue removeObject:bubble];
}

#pragma mark - queries
- (float) sliceWidth
{
    return M_PI * 2.0f / [self numSlices];
}

- (unsigned int) itemIndexAtAngle:(float)absAngle forNumItems:(unsigned int)numItems
{
    unsigned int itemIndex = 0;
    if(0.0f < absAngle)
    {
        float widthAngle = [self sliceWidth];
        
        // offset by width/2 because the item-angles start at -(width/2) for index 0 (whose mid is at 0.0f)
        float itemIndexFloat = (absAngle + (widthAngle / 2.0f)) / widthAngle;
        itemIndex = (unsigned int) floorf(itemIndexFloat);        
    }
    
    if(itemIndex >= numItems)
    {
        itemIndex = numItems - 1;
    }
    
    return itemIndex;
}

- (float) midAngleAtItemIndex:(unsigned int)index forNumItems:(unsigned int)numItems
{
    float mid = index * [self sliceWidth];
    return mid;
}

- (float) maxItemMaxAngleForNumItems:(unsigned int)numItems
{
    return ([self midAngleAtItemIndex:numItems forNumItems:numItems] - ([self sliceWidth]/2.0f));
}

- (float) minItemMinAngle
{
    return -([self sliceWidth] / 2.0f);
}

- (CGAffineTransform) renderTransformFromLogicalTransform:(CGAffineTransform)xform
{
    return CGAffineTransformRotate(xform, kWheelRenderOffsetFactor * [self sliceWidth]);    
}

- (NSArray*) hiddenSliceIndicesWhenAt:(unsigned int)index
{
    unsigned int num = ([self numSlices] / 2.0f) - 1;
    NSMutableArray* resultArray = [NSMutableArray arrayWithCapacity:num];
    unsigned int begin = (index + num - 2) % [self numSlices];
    for(unsigned int i=0; i < num; ++i)
    {
        unsigned int curIndex = (begin + i) % [self numSlices];
        [resultArray addObject:[NSNumber numberWithUnsignedInt:curIndex]];
    }
    return resultArray;
}

- (BOOL) isWheelStateHidden
{
    return (kWheelStateHidden == _state);
}

#pragma mark - internal
- (void) createWheelRenderWithFrame:(CGRect)wheelFrame
{
    // create container for wheel
    _wheelView = [[UIView alloc] initWithFrame:wheelFrame];
    _container = [[UIView alloc] initWithFrame:_wheelView.bounds];
    self.slices = [NSMutableArray arrayWithCapacity:self.numSlices];
    if(0 == ([self numSlices] % 2))
    {
        [self buildSlicesEven];
    }
    else 
    {
        [self buildSlicesOdd];
    }

    for(WheelSlice* curSlice in self.slices)
    {
        [self.container addSubview:[curSlice view]];
    }
    
    _logicalTransform = CGAffineTransformIdentity;
    self.container.transform = [self renderTransformFromLogicalTransform:_logicalTransform];
    self.container.userInteractionEnabled = NO;
    _wheelView.userInteractionEnabled = NO;
    [_wheelView addSubview:[self container]];
    [self addSubview:_wheelView];
}


static const float kPreviewButtonOkSizeFrac = 0.26f;
static const float kPreviewButtonOkXFrac = 0.73f;
static const float kPreviewButtonOkYFrac = 0.39f;
static const float kPreviewButtonCloseSizeFrac = 0.16f;
static const float kPreviewButtonCloseXFrac = 0.75f;
static const float kPreviewButtonCloseYFrac = 0.66f;
static const float kPreviewButtonBorderWidth = 1.8f;
static const float kPreviewBorderWidth = 14.5f;
static const float kPreviewLabelBgOriginY = 0.7f;
static const float kPreviewLabelOriginY = 0.05f;
static const float kPreviewLabelTextSize = 10.0f;
static const float kPreviewCancelImageInset = 6.0f;
- (void) createPreviewCircleWithFrame:(CGRect)previewFrame
{
    _previewView = [[UIView alloc] initWithFrame:previewFrame];
    [_previewView setBackgroundColor:[UIColor clearColor]];
    [_previewView setClipsToBounds:NO];
    [self addSubview:_previewView];
    _previewCircle = [[UIView alloc] initWithFrame:[_previewView bounds]];
    [_previewCircle setBackgroundColor:[UIColor greenColor]];
    
    UIColor* bgColor = [UIColor darkGrayColor];
    if([self.dataSource respondsToSelector:@selector(previewColorForWheel:)])
    {
        bgColor = [self.dataSource previewColorForWheel:self];
    }
    UIColor* borderColor = [UIColor darkGrayColor];
    if([self.dataSource respondsToSelector:@selector(previewBorderColorForWheel:)])
    {
        borderColor = [self.dataSource previewBorderColorForWheel:self];
    }
    UIColor* buttonColor = [UIColor darkGrayColor];
    if([self.dataSource respondsToSelector:@selector(previewButtonColorForWheel:)])
    {
        buttonColor = [self.dataSource previewButtonColorForWheel:self];
    }
    UIColor* buttonBorderColor = [UIColor darkGrayColor];
    if([self.dataSource respondsToSelector:@selector(previewButtonBorderColorForWheel:)])
    {
        buttonBorderColor = [self.dataSource previewButtonBorderColorForWheel:self];
    }
    // previewImageView that can optionally cover up the content
    _previewImageView = [[UIImageView alloc] initWithFrame:[_previewView bounds]];
    _previewImageView.backgroundColor = [UIColor clearColor];
    [_previewCircle addSubview:_previewImageView];

    // add the preview circle into the container view
    [_previewView addSubview:_previewCircle];
    
    // text label container
    CGRect labelBgFrame = CGRectMake(0.0f,
                                     kPreviewLabelBgOriginY * previewFrame.size.height,
                                     previewFrame.size.width,
                                     (1.0f - kPreviewLabelBgOriginY) * previewFrame.size.height);
    UIView* labelBg = [[UIView alloc] initWithFrame:labelBgFrame];
    [labelBg setBackgroundColor:borderColor];
    [_previewCircle addSubview:labelBg];
    self.previewLabelBg = labelBg;
    CGRect labelFrame = labelBgFrame;
    labelFrame.origin = CGPointMake(0.0f, -(kPreviewLabelOriginY * previewFrame.size.height));
    UILabel* label = [[UILabel alloc] initWithFrame:labelFrame];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setFont:[UIFont fontWithName:@"Marker Felt" size:kPreviewLabelTextSize]];
    [label setTextColor:[UIColor whiteColor]];
    [label setTextAlignment:UITextAlignmentCenter];
    [self.previewLabelBg addSubview:label];
    self.previewLabel = label;
    
    CGRect okRect = CGRectMake(kPreviewButtonOkXFrac * previewFrame.size.width,
                               kPreviewButtonOkYFrac * previewFrame.size.width,
                               kPreviewButtonOkSizeFrac * previewFrame.size.width,
                               kPreviewButtonOkSizeFrac * previewFrame.size.height);
    self.okView = [[LabelCircle alloc] initWithFrame:okRect
                                         borderWidth:kPreviewButtonBorderWidth
                                         borderColor:buttonBorderColor
                                             bgColor:buttonColor];
    [self.okView.label setText:@"Yes"];
    [_previewView addSubview:[self okView]];
    _buttonOk = [UIButton buttonWithType:UIButtonTypeCustom];
    [_buttonOk setBackgroundColor:[UIColor clearColor]];
    [_buttonOk setFrame:[self.okView bounds]];
    [_buttonOk addTarget:self action:@selector(didOkInPreview:) forControlEvents:UIControlEventTouchUpInside];
    [self.okView addSubview:_buttonOk];
    
    CGRect closeRect = CGRectMake(kPreviewButtonCloseXFrac * previewFrame.size.width,
                                  kPreviewButtonCloseYFrac * previewFrame.size.width,
                                  kPreviewButtonCloseSizeFrac * previewFrame.size.width,
                                  kPreviewButtonCloseSizeFrac * previewFrame.size.height);
    self.cancelView = [[LabelCircle alloc] initWithFrame:closeRect
                                         borderWidth:kPreviewButtonBorderWidth
                                         borderColor:buttonBorderColor
                                             bgColor:buttonColor];
    [_previewView addSubview:[self cancelView]];
    UIImageView* cancelImageView = [[UIImageView alloc] initWithFrame:CGRectInset(self.cancelView.bounds, kPreviewCancelImageInset, kPreviewCancelImageInset)];
    [cancelImageView setImage:[UIImage imageNamed:@"x.png"]];
    [self.cancelView addSubview:cancelImageView];
    _buttonClose = [UIButton buttonWithType:UIButtonTypeCustom];
    [_buttonClose setFrame:[self.cancelView bounds]];
    [_buttonClose addTarget:self action:@selector(didCloseInPreview:) forControlEvents:UIControlEventTouchUpInside];
    [self.cancelView addSubview:_buttonClose];
    
    // add the content to the bottom-most layer in the preview circle
    [PogUIUtility setCircleForView:_previewCircle withBorderWidth:kPreviewBorderWidth borderColor:borderColor];
    _previewContent = [self.dataSource wheel:self previewContentInitAtIndex:0];
    [_previewCircle addSubview:_previewContent];
    [_previewCircle sendSubviewToBack:_previewContent];
    [_previewCircle setUserInteractionEnabled:NO];
}

- (float) distFromCenter:(CGPoint)point
{
    CGPoint center = CGPointMake(self.container.bounds.size.width/2,
                                 self.container.bounds.size.height/2);
    float dx = point.x - center.x;
    float dy = point.y - center.y;
    return sqrt(dx*dx + dy*dy);
}

// Slices are ordered clockwise starting at the negative x-axis
- (void) buildSlicesOdd
{
    CGFloat fanWidth = [self sliceWidth];
    CGFloat mid = 0;
    for (unsigned int i = 0; i < [self numSlices]; i++) 
    {
        float midAngle = mid;
        float minAngle = mid - (fanWidth / 2.0f);
        float maxAngle = mid + (fanWidth / 2.0f);
        WheelSlice* newSlice = [[WheelSlice alloc] initWithMin:minAngle
                                                           mid:midAngle
                                                           max:maxAngle
                                                        radius:self.container.bounds.size.width * 0.5f
                                                   sliceLength:self.container.bounds.size.width * kSliceLengthFrac
                                                         angle:fanWidth
                                                         index:i];
        [self.slices addObject:newSlice];

        mid -= fanWidth;
        if (newSlice.minAngle < - M_PI) 
        {
            mid = -mid;
            mid -= fanWidth; 
        }
    }
}

- (void) buildSlicesEven
{
    CGFloat fanWidth = [self sliceWidth];
    CGFloat mid = 0;
    for (unsigned int i = 0; i < [self numSlices]; i++) 
    {
        float midAngle = mid;
        float minAngle = mid - (fanWidth/2);
        float maxAngle = mid + (fanWidth/2);
        if ((maxAngle - fanWidth) < - M_PI) 
        {
            mid = M_PI;
            midAngle = mid;
            minAngle = fabsf(maxAngle);
        }
        WheelSlice* newSlice = [[WheelSlice alloc] initWithMin:minAngle
                                                           mid:midAngle
                                                           max:maxAngle
                                                        radius:self.container.bounds.size.width * 0.5f
                                                   sliceLength:self.container.bounds.size.width * kSliceLengthFrac
                                                         angle:fanWidth
                                                         index:i];
        [self.slices addObject:newSlice];

        mid -= fanWidth;
    }
}

- (void) initBeaconSlots
{
    [self refreshBeaconSlotsWithSelectedBeacon:0 selectedSlice:0];
}

// refresh rendering of items on wheel as new slices come into view and old slices go out
- (void) refreshBeaconSlotsWithSelectedBeacon:(unsigned int)beaconIndex selectedSlice:(unsigned int)sliceIndex
{
    // clear hidden slices
    NSArray* hiddenIndices = [self hiddenSliceIndicesWhenAt:sliceIndex];
    for(NSNumber* cur in hiddenIndices)
    {
        WheelSlice* curSlice = [self.slices objectAtIndex:[cur unsignedIntValue]];
        curSlice.value = -1;
        [curSlice wheel:self setContentBubble:nil];
        [curSlice.view setHidden:YES];
    }
    
    unsigned numItems = [self.dataSource numItemsInWheel:self];
    int begin = beaconIndex - ((int) kWheelRenderOffsetFactor);
    if(0 > begin)
    {
        begin = 0;
    }
    unsigned int end = beaconIndex + (self.numSlices / 2) + 1;
    for(unsigned int i = begin; i < end; ++i)
    {
        unsigned int iterSliceIndex = i % self.numSlices;
        WheelSlice* curSlice = [self.slices objectAtIndex:iterSliceIndex];
        if(curSlice)
        {
            UIView* sliceView = [curSlice view];

            if(i < numItems)
            {
                [curSlice wheel:self setContentBubble:nil];
                curSlice.value = i;
                [sliceView setHidden:NO];
                WheelBubble* contentView = [self.dataSource wheel:self bubbleAtIndex:iterSliceIndex];
                [curSlice wheel:self setContentBubble:contentView];
                [self levelContentViewForSlice:curSlice item:0 numItems:numItems];
            }
        }
    }
    // special case when beaconIndex is at zero :
    // it is possible that spring is engaged at this point;
    // so, we need to clear out a few slots to the left
    if(0 == beaconIndex)
    {
        int curSliceIndex = sliceIndex - 1;
        if(0 > curSliceIndex)
        {
            curSliceIndex = self.numSlices - 1;
        }
        for(unsigned int i = 0; i < 3; ++i)
        {
            WheelSlice* curSlice = [self.slices objectAtIndex:curSliceIndex];
            curSlice.value = -1;
            [curSlice wheel:self setContentBubble:nil];
            [curSlice.view setHidden:YES];
            --curSliceIndex;
            if(0 > curSliceIndex)
            {
                curSliceIndex = self.numSlices - 1;
            }
        }
    }
}

- (void) levelContentViewForSlice:(WheelSlice*)slice item:(unsigned int)itemIndex numItems:(unsigned int)numItems
{
    WheelBubble* cur = [slice contentBubble];
    CGAffineTransform invContainerXform = CGAffineTransformInvert(self.container.transform);
    CGAffineTransform invSliceXform = CGAffineTransformInvert(slice.view.transform);
    CGAffineTransform contentXform = CGAffineTransformConcat(invSliceXform, invContainerXform);
    
    CGAffineTransform scaledXform = [self scaleSlice:slice withItem:itemIndex overNumItems:numItems absAngle:_absAngle];
    
    cur.transform = CGAffineTransformConcat(contentXform, scaledXform);
}

- (void) levelContentViewForSlice:(WheelSlice *)slice
{
    WheelBubble* cur = [slice contentBubble];
    CGAffineTransform invContainerXform = CGAffineTransformInvert(self.container.transform);
    CGAffineTransform invSliceXform = CGAffineTransformInvert(slice.view.transform);
    CGAffineTransform contentXform = CGAffineTransformConcat(invSliceXform, invContainerXform);
    
    cur.transform = contentXform;
}

- (void) levelContentViewsWithItem:(unsigned int)itemIndex numItems:(unsigned int)numItems
{
    for(unsigned int i = 0; i < [self numSlices]; ++i)
    {
        WheelSlice* curSlice = [self.slices objectAtIndex:i];
        if(0 <= [curSlice value])
        {
            [self levelContentViewForSlice:curSlice item:itemIndex numItems:numItems];
        }
        else 
        {
            [self levelContentViewForSlice:curSlice];
        }
    }
}

static const float kSelectedItemScale = 2.2f;
static const float kSelectedOffset = -6.5f;
- (CGAffineTransform) scaleSlice:(WheelSlice*)slice 
           withItem:(unsigned int)itemIndex 
       overNumItems:(unsigned int)numItems
           absAngle:(float)absAng
{
    CGAffineTransform result = CGAffineTransformIdentity;
    if([slice contentBubble])
    {
        unsigned int sliceItemIndex = [slice value];
        float mid = [self midAngleAtItemIndex:sliceItemIndex forNumItems:(unsigned int)numItems];
        float min = mid - ([self sliceWidth] * 3.5f);
        float max = mid + ([self sliceWidth] * 3.5f);
        
        float scaleInput = (absAng - min) / (max - min);
        if((0.0f <= scaleInput) && (scaleInput <= 1.0f))
        {
            // a is height of curve
            // b is center of curve
            // c is width of curve
            float scaleFactor = [PogUIUtility gaussianFor:scaleInput withA:0.43f b:0.5f c:0.10f];
            
            // the scale if offset by 0.5f because we want the flat part of the curve to be at scale 1.0f
            // (kSelectedItemScale is 2.0f)
            CGAffineTransform scaledTransform = CGAffineTransformScale(CGAffineTransformIdentity, 
                                                                       (scaleFactor + 0.5f) * kSelectedItemScale,
                                                                       (scaleFactor + 0.5f) * kSelectedItemScale);
            
            float offsetFactor = [PogUIUtility gaussianFor:scaleInput withA:1.0f b:0.5f c:0.08f];
            result = CGAffineTransformTranslate(scaledTransform, offsetFactor * kSelectedOffset, 0.0f);
        }
    }
    return result;
}

- (void) showWheelAnimated:(BOOL)isAnimated withDelay:(float)delay
{
    [self.delegate wheel:self willShowAtIndex:_selectedBeacon];
    if(isAnimated)
    {
        [self setHidden:NO];
        _state = kWheelStateTransitionIn;
        
        // show the bubbles first
        CGAffineTransform inStep = CGAffineTransformRotate(_logicalTransform, -M_PI + (kWheelRenderOffsetFactor * [self sliceWidth]));
        [UIView animateWithDuration:0.2f
                              delay:delay
                            options:UIViewAnimationCurveEaseInOut
                         animations:^(void){
                             self.container.transform = [self renderTransformFromLogicalTransform:inStep];
                             self.container.alpha = 1.0f;
                         }
                         completion:^(BOOL finished){
                             [UIView animateWithDuration:0.1f
                                                   delay:0.0f
                                                 options:UIViewAnimationCurveEaseInOut
                                              animations:^(void){
                                                  self.container.transform = [self renderTransformFromLogicalTransform:_pushedWheelTransform];
                                              }
                                              completion:^(BOOL finished){
                                                  _logicalTransform = _pushedWheelTransform;
                                                  _state = kWheelStateActive;
                                              }];
                         }];
        
        // then expand the preview circle
        [UIView animateWithDuration:0.2f
                              delay:delay + 0.2f
                            options:UIViewAnimationCurveEaseInOut
                         animations:^(void){
                             [_previewView setTransform:CGAffineTransformIdentity];
                             [_previewView setAlpha:1.0f];
                         }
                         completion:nil];
    }
    else 
    {
        [self setHidden:NO];
        _state = kWheelStateActive;
        _logicalTransform = _pushedWheelTransform;
        self.container.transform = [self renderTransformFromLogicalTransform:_logicalTransform];
        self.container.alpha = 1.0f;
        [_previewView setTransform:CGAffineTransformIdentity];
        [_previewView setAlpha:1.0f];
    }
}

- (void) hideWheelAnimated:(BOOL)isAnimated withDelay:(float)delay
{
    CGAffineTransform outTransform = CGAffineTransformRotate(_logicalTransform, M_PI - (kWheelRenderOffsetFactor * [self sliceWidth]));
    
    _pushedWheelTransform = _logicalTransform;
    [self.delegate wheel:self willHideAtIndex:_selectedBeacon];
    if(isAnimated)
    {
        _state = kWheelStateTransitionOut;

        // preview circle shrinks down first
        [UIView animateWithDuration:0.1f
                              delay:delay
                            options:UIViewAnimationCurveLinear
                         animations:^(void){
                             [_previewView setTransform:_hiddenPreviewTransform];
                             [_previewView setAlpha:0.0f];
                         }
                         completion:nil];

        // then transition out the bubbles
        [UIView animateWithDuration:0.1f 
                              delay:delay + 0.1f
                            options:UIViewAnimationCurveLinear
                         animations:^(void){
                             self.container.transform = [self renderTransformFromLogicalTransform:outTransform];
                             self.container.alpha = 0.0f;
                         }
                         completion:^(BOOL finished){
                             _logicalTransform = outTransform;
                             _state = kWheelStateHidden;
                             [self setHidden:YES];
                         }];
        
    }
    else
    {
        _state = kWheelStateHidden;
        _logicalTransform = outTransform;
        self.container.transform = [self renderTransformFromLogicalTransform:_logicalTransform];
        self.container.alpha = 0.0f;
        [_previewView setTransform:_hiddenPreviewTransform];
        [_previewView setAlpha:0.0f];
        [self setHidden:YES];
    }
}

#pragma mark - preview controls
- (void) didOkInPreview:(id)sender
{
    [self hideWheelAnimated:YES withDelay:0.0f];
    [self.delegate wheel:self didPressOkOnIndex:[self selectedSlice]];
}

- (void) didCloseInPreview:(id)sender
{
    [self hideWheelAnimated:YES withDelay:0.0f];
    [self.delegate wheel:self didPressCloseOnIndex:[self selectedSlice]];
}

#pragma mark - UIControl
- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event 
{
    BOOL beginTracking = YES;
    CGPoint touchPoint = [touch locationInView:_wheelView];
    float dist = [self distFromCenter:touchPoint];
    float minDist = _container.bounds.size.width * kSliceTouchMaxDistFrac * 0.3f;
    float maxDist = _container.bounds.size.width * kSliceTouchMaxDistFrac;
    if((minDist <= dist) && (dist <= maxDist))
    {
        float dx = touchPoint.x - self.container.center.x;
        float dy = touchPoint.y - self.container.center.y;
        
        // angle at start
        _deltaAngle = atan2(dy,dx); 
        _prevAngle = _deltaAngle;
        _prevIndex = self.selectedSlice;

        // transform at start
        _startTransform = _logicalTransform;
        beginTracking = YES;
        _springEngaged = NO;
        _absStartAngle = _absAngle;
    }
    else 
    {
        // ignore if user taps too close to the center of the wheel
        beginTracking = NO;
    }
    return beginTracking;
}

- (void) cancelTrackingWithEvent:(UIEvent *)event
{
    NSLog(@"TRACKING CANCELED!!");
}

- (BOOL)continueTrackingWithTouch:(UITouch*)touch withEvent:(UIEvent*)event
{
    BOOL shouldEndTracking = NO;
    CGPoint pt = [touch locationInView:_wheelView];
    float dx = pt.x  - self.container.center.x;
    float dy = pt.y  - self.container.center.y;
    float ang = atan2(dy,dx);
    float angleDifference = _deltaAngle - ang;
    CGAffineTransform newTransform = CGAffineTransformRotate(_startTransform, -angleDifference);
        
    unsigned int numItems = [self.dataSource numItemsInWheel:self];
    _absAngle = _absStartAngle + angleDifference;
    unsigned int beaconSlot = [self itemIndexAtAngle:_absAngle forNumItems:numItems];
    
    // transform.a is cos(t) and transform.b is sin(t) according
    // to documentation of CGAffineTransformMakeRotation
    CGFloat radians = atan2f(newTransform.b, newTransform.a);
    unsigned int newSelectedSlice = self.selectedSlice;
    for (WheelSlice *cur in [self slices]) 
    {
        // check if min and max are different signs (when numSectors is even)
        if((cur.minAngle > 0.0f) && (cur.maxAngle < 0.0f))
        {
            if((cur.maxAngle > radians) || (cur.minAngle < radians))
            {
                newSelectedSlice = cur.index;
                break;
            }
        }
        else if ((radians > cur.minAngle) && (radians < cur.maxAngle)) 
        {
            newSelectedSlice = cur.index;
			break;
        }
    }
    
    float absMinAngle = [self minItemMinAngle];
    float absMaxAngle = [self maxItemMaxAngleForNumItems:numItems];
    if((_absAngle < absMinAngle) || (_absAngle > absMaxAngle))
    {
        if(!_springEngaged)
        {
            _springEngaged = YES;
            _springTargetIndex = self.selectedSlice;
            if(_absAngle < [self minItemMinAngle])
            {
                _springBeaconSlot = 0;
            }
            else
            {
                _springBeaconSlot = numItems - 1;
            }
            NSLog(@"Spring engaged %d!! absAngle %f\n", _springBeaconSlot, _absAngle);
        }
        
        CGFloat bufferWidth = [self sliceWidth];
        if((_absAngle < (absMinAngle - bufferWidth)) ||
           (_absAngle > (absMaxAngle - bufferWidth)))
        {
            // stop player motion when rotation is one slice beyond either
            // side of the selection range
            shouldEndTracking = YES;
        }
    }
    else 
    {
        // in range, cancel spring
        _springEngaged = NO;
        
        // update beacon slots
        [self refreshBeaconSlotsWithSelectedBeacon:beaconSlot selectedSlice:newSelectedSlice];
    }
    
    // commit changes
    _logicalTransform = newTransform;
    self.container.transform = [self renderTransformFromLogicalTransform:_logicalTransform];
    _prevIndex = self.selectedSlice;
    self.selectedSlice = newSelectedSlice;
    _prevAngle = ang;
        
    if(shouldEndTracking && _springEngaged)
    {
        beaconSlot = _springBeaconSlot;
        self.selectedSlice = _springTargetIndex;

        // if we are ending-tracking here, endTrackingWithTouch would not get called
        // so, set absAngle here
        if(shouldEndTracking)
        {
            _absAngle = [self midAngleAtItemIndex:beaconSlot forNumItems:numItems];
        }

        // when we return NO from here, the endTrackingWithTouch method will not
        // get called; so, need to handle the spring back ourselves here
        WheelSlice* springSlice = [self.slices objectAtIndex:_springTargetIndex];
        CGFloat springAng = radians - [springSlice midAngle];

        CGAffineTransform t = CGAffineTransformRotate(_logicalTransform, -springAng);
        [UIView animateWithDuration:0.2f
                              delay:0.0f
                            options:UIViewAnimationCurveLinear 
                            animations:^(void){
                                self.container.transform = [self renderTransformFromLogicalTransform:t];
                                [self levelContentViewsWithItem:beaconSlot numItems:numItems];                                
                            }
                            completion:^(BOOL finished){
                                _logicalTransform = t;
                             
                                // commit beacon slot selection
                                if(beaconSlot != _selectedBeacon) 
                                {
                                    _selectedBeacon = beaconSlot;
                                    [self.delegate wheel:self didMoveTo:_selectedBeacon];
                                }
                                
                                // if we are ending-tracking here, endTrackingWithTouch would not get called
                                // so, inform delegate here
                                if(shouldEndTracking)
                                {
                                    [self.delegate wheel:self didSettleAt:_selectedBeacon];
                                }
                            }];
        /*
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.2];
        self.container.transform = [self renderTransformFromLogicalTransform:_logicalTransform];
        [self levelContentViewsWithItem:beaconSlot numItems:numItems];
        [UIView commitAnimations];
         */
    }
    else 
    {
        [self levelContentViewsWithItem:beaconSlot numItems:numItems];

        // commit beacon slot selection
        if(beaconSlot != _selectedBeacon) 
        {
            _selectedBeacon = beaconSlot;
            [self.delegate wheel:self didMoveTo:_selectedBeacon];
        }
    }
    

    return !shouldEndTracking;
}

- (void)endTrackingWithTouch:(UITouch*)touch withEvent:(UIEvent*)event
{
    unsigned int numItems = [self.dataSource numItemsInWheel:self];
    unsigned int beaconSlot = [self itemIndexAtAngle:_absAngle forNumItems:numItems];

    // transform.a is cos(t) and transform.b is sin(t) according
    // to documentation of CGAffineTransformMakeRotation
    CGFloat radians = atan2f(_logicalTransform.b, _logicalTransform.a);
    CGFloat newVal = 0.0;
    for (WheelSlice *cur in [self slices]) 
    {
        // check if min and max are different signs (when numSectors is even)
        if((cur.minAngle > 0.0f) && (cur.maxAngle < 0.0f))
        {
            if((cur.maxAngle > radians) || (cur.minAngle < radians))
            {
                if(radians > 0.0f)
                {
                    newVal = radians - M_PI;
                }
                else 
                {
                    newVal = M_PI + radians;
                }
                self.selectedSlice = cur.index;
            }
        }
        else if ((radians > cur.minAngle) && (radians < cur.maxAngle)) 
        {
            newVal = radians - cur.midAngle;
            self.selectedSlice = cur.index;
			break;
        }
    }

    if(_springEngaged)
    {
        beaconSlot = _springBeaconSlot;
        self.selectedSlice = _springTargetIndex;

        WheelSlice* springSlice = [self.slices objectAtIndex:_springTargetIndex];
        CGFloat springAng = radians - [springSlice midAngle];
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.2];
        CGAffineTransform t = CGAffineTransformRotate(_logicalTransform, -springAng);
        _logicalTransform = t;
        self.container.transform = [self renderTransformFromLogicalTransform:_logicalTransform];

        // important: levelContentViewsWithItem relies on _absAngle to scale the selected bubble
        _absAngle = [self midAngleAtItemIndex:beaconSlot forNumItems:numItems];
        [self levelContentViewsWithItem:beaconSlot numItems:numItems];
        [UIView commitAnimations];
//        [self.delegate wheel:self didSettleAt:_selectedBeacon];
    }
    else 
    {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.2];
        CGAffineTransform t = CGAffineTransformRotate(_logicalTransform, -newVal);
        _logicalTransform = t;
        self.container.transform = [self renderTransformFromLogicalTransform:_logicalTransform];

        // important: levelContentViewsWithItem relies on _absAngle to scale the selected bubble
        _absAngle = [self midAngleAtItemIndex:beaconSlot forNumItems:numItems];
        [self levelContentViewsWithItem:beaconSlot numItems:numItems];
        [UIView commitAnimations];
    }
    
    _selectedBeacon = beaconSlot;
    [self.delegate wheel:self didSettleAt:_selectedBeacon];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
