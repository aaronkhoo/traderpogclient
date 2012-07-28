//
//  KnobControl.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/6/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "KnobControl.h"
#import "KnobSlice.h"

static const float kRenderOffsetFactor = 1.0f; // offset angle is this factor multiplied with sliceWidth 

// units in fraction of Knob-radius
static const float kKnobCenterRadiusFrac = 0.7f;

@interface KnobControl ()
{
    CGAffineTransform _logicalTransform;
    float _deltaAngle;
    CGAffineTransform _startTransform;
}
@property (nonatomic,strong) UIImageView* backgroundImageView;
- (float) sliceWidth;
- (CGAffineTransform) renderTransformFromLogicalTransform:(CGAffineTransform)xform reverse:(BOOL)reverse;
- (void) buildSlicesEven;
- (void) buildSlicesOdd;
- (void) createWheelRender;
- (void) createCenterButton;
- (float) distFromCenter:(CGPoint)point;
- (void) refreshSliceViewDidSelect;
- (void) refreshSliceViewDidBeginTouch;
- (void) didPressCenterButton:(id)sender;
@end

@implementation KnobControl
@synthesize numSlices = _numSlices;
@synthesize slices = _slices;
@synthesize container = _container;
@synthesize selectedSlice = _selectedSlice;
@synthesize centerButton;
@synthesize backgroundImageView;
@synthesize delegate;

- (id)initWithFrame:(CGRect)frame 
          numSlices:(unsigned int)numSlices
{
    self = [super initWithFrame:frame];
    if (self) 
    {
        _numSlices = numSlices;
        _logicalTransform = CGAffineTransformIdentity;
        _selectedSlice = 0;
        
        [self createWheelRender];
        [self createCenterButton];
        
        // initial refresh of sliceview
        [self refreshSliceViewDidSelect];
    }
    return self;
}

- (void) setBackgroundImage:(UIImage *)image
{
    [self.backgroundImageView setImage:image];
}

#pragma mark - internal methods
- (CGAffineTransform) renderTransformFromLogicalTransform:(CGAffineTransform)xform reverse:(BOOL)reverse
{
    float factor = 1.0f;
    if(reverse)
    {
        factor = -1.0f;
    }
    return CGAffineTransformRotate(xform, factor * kRenderOffsetFactor * [self sliceWidth]);    
}

- (float) sliceWidth
{
    return M_PI * 2.0f / [self numSlices];
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
        KnobSlice* newSlice = [[KnobSlice alloc] initWithMin:minAngle
                                                                 mid:midAngle
                                                                 max:maxAngle
                                                              radius:self.container.bounds.size.width / 2.0f
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
        KnobSlice* newSlice = [[KnobSlice alloc] initWithMin:minAngle
                                                                 mid:midAngle
                                                                 max:maxAngle
                                                              radius:self.container.bounds.size.width / 2.0f
                                                               angle:fanWidth
                                                               index:i];
        [self.slices addObject:newSlice];
        
        mid -= fanWidth;
    }
}

- (void) createWheelRender
{
    _container = [[UIView alloc] initWithFrame:self.bounds];
    
    // setup background-image-view
    // Note on transform: the wheel rendering transform is offset such that the current selection is upward;
    // however, we need the background to not offset; thus the reverse transform here;
    self.backgroundImageView = [[UIImageView alloc] initWithFrame:self.bounds];
    [self.backgroundImageView setTransform:[self renderTransformFromLogicalTransform:_logicalTransform reverse:YES]];
    [self.container addSubview:[self backgroundImageView]];

    // setup slices
    self.slices = [NSMutableArray arrayWithCapacity:self.numSlices];
    if(0 == ([self numSlices] % 2))
    {
        [self buildSlicesEven];
    }
    else 
    {
        [self buildSlicesOdd];
    }
    
    for(KnobSlice* curSlice in self.slices)
    {
        [self.container addSubview:[curSlice view]];
    }
    
    self.container.transform = [self renderTransformFromLogicalTransform:_logicalTransform reverse:NO];
    self.container.userInteractionEnabled = NO;
    [self addSubview:[self container]];    

}

- (void) createCenterButton
{
    self.centerButton = [UIButton buttonWithType:UIButtonTypeCustom];
    float containerRadius = _container.bounds.size.width * 0.5f;
    float centerRadius = containerRadius * kKnobCenterRadiusFrac;
    float centerWidth = centerRadius * 1.3f;
    float centerHeight = centerRadius * 0.8f;
    CGRect centerRect = CGRectMake(containerRadius - (centerWidth * 0.5f), 
                                   containerRadius - centerHeight, 
                                   centerWidth, centerHeight);
    [self.centerButton setFrame:centerRect];
    [self.centerButton setBackgroundColor:[UIColor clearColor]];
    [self.centerButton addTarget:self action:@selector(didPressCenterButton:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:[self centerButton]];
}

- (float) distFromCenter:(CGPoint)point
{
    CGPoint center = CGPointMake(self.bounds.size.width/2, 
                                 self.bounds.size.height/2);
    float dx = point.x - center.x;
    float dy = point.y - center.y;
    return sqrt(dx*dx + dy*dy);
}

- (void) refreshSliceViewDidSelect
{
    // make selected slice bigger
    unsigned int sliceIndex = 0;
    for(KnobSlice* cur in _slices)
    {
        if([self selectedSlice] == sliceIndex)
        {
            [UIView animateWithDuration:0.2f 
                             animations:^(void){
                                 [cur useBigText];
                             }
                             completion:nil];
        }
        else 
        {
            [cur.view setHidden:YES];
        }
        ++sliceIndex;
    }
}

- (void) refreshSliceViewDidBeginTouch
{
    // unhide all slices and make them the same size
    unsigned int sliceIndex = 0;
    for(KnobSlice* cur in _slices)
    {
        if([self selectedSlice] == sliceIndex)
        {
            [UIView animateWithDuration:0.2f 
                             animations:^(void){
                                 [cur useSmallText];
                             }
                             completion:nil];            
        }
        [cur.view setHidden:NO];
        ++sliceIndex;
    }
}

#pragma mark - UIControl
- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event 
{
    BOOL beginTracking = YES;
    CGPoint touchPoint = [touch locationInView:self];
    float dist = [self distFromCenter:touchPoint];
    float minDist = _container.bounds.size.width * 0.5f * kKnobCenterRadiusFrac;
    float maxDist = _container.bounds.size.width * 0.5f;
    if((minDist <= dist) && (dist <= maxDist))
    {
        float dx = touchPoint.x - self.container.center.x;
        float dy = touchPoint.y - self.container.center.y;
        
        // angle at start
        _deltaAngle = atan2(dy,dx); 
        
        // transform at start
        _startTransform = _logicalTransform;
        beginTracking = YES;
        
        [self refreshSliceViewDidBeginTouch];
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
    CGPoint pt = [touch locationInView:self];
    float dx = pt.x  - self.container.center.x;
    float dy = pt.y  - self.container.center.y;
    float ang = atan2(dy,dx);
    float angleDifference = _deltaAngle - ang;
    CGAffineTransform newTransform = CGAffineTransformRotate(_startTransform, -angleDifference);
    
    // transform.a is cos(t) and transform.b is sin(t) according
    // to documentation of CGAffineTransformMakeRotation
    CGFloat radians = atan2f(newTransform.b, newTransform.a);
    unsigned int newSelectedSlice = self.selectedSlice;
    unsigned int index = 0;
    for (KnobSlice *cur in [self slices]) 
    {
        // check if min and max are different signs (when numSectors is even)
        if((cur.minAngle > 0.0f) && (cur.maxAngle < 0.0f))
        {
            if((cur.maxAngle > radians) || (cur.minAngle < radians))
            {
                newSelectedSlice = index;
                break;
            }
        }
        else if ((radians > cur.minAngle) && (radians < cur.maxAngle)) 
        {
            newSelectedSlice = index;
			break;
        }
        ++index;
    }
    
    // commit changes
    _logicalTransform = newTransform;
    self.container.transform = [self renderTransformFromLogicalTransform:_logicalTransform reverse:NO];
    self.selectedSlice = newSelectedSlice;
    
    return YES;
}

- (void)endTrackingWithTouch:(UITouch*)touch withEvent:(UIEvent*)event
{
    // transform.a is cos(t) and transform.b is sin(t) according
    // to documentation of CGAffineTransformMakeRotation
    CGFloat radians = atan2f(_logicalTransform.b, _logicalTransform.a);
    CGFloat newVal = 0.0;
    unsigned int index = 0;
    for (KnobSlice *cur in [self slices]) 
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
                self.selectedSlice = index;
            }
        }
        else if ((radians > cur.minAngle) && (radians < cur.maxAngle)) 
        {
            newVal = radians - cur.midAngle;
            self.selectedSlice = index;
			break;
        }
        ++index;
    }
    
    // animate to resting position
    {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.2];
        CGAffineTransform t = CGAffineTransformRotate(_logicalTransform, -newVal);
        _logicalTransform = t;
        self.container.transform = [self renderTransformFromLogicalTransform:_logicalTransform reverse:NO];
        [UIView commitAnimations];
    }
    
    [self refreshSliceViewDidSelect];
}

#pragma mark - button actions
- (void) didPressCenterButton:(id)sender
{
    [self.delegate didPressKnobCenter];
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
