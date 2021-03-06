//
//  KnobControl.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/6/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "KnobControl.h"
#import "KnobSlice.h"
#import "PogUIUtility.h"
#import "CircleView.h"
#import "SoundManager.h"
#import <QuartzCore/QuartzCore.h>

static const float kRenderOffsetFactor = 1.0f; // offset angle is this factor multiplied with sliceWidth 

static const float kKnobBorderWidth = 5.0f;

// units in fraction of KnobControl width
static const float kKnobRenderFrac = 0.7f;
static const float kKnobDragFrac = kKnobRenderFrac - 0.3f;
static const float kKnobRotateBeginX = 0.26f;
static const float kKnobButtonWidth = 0.43f;
static const float kKnobButtonHeight = 0.7f;

@interface KnobControl ()
{
    CGAffineTransform _logicalTransform;
    float _deltaAngle;
    CGAffineTransform _startTransform;
}
@property (nonatomic,strong) CircleView* circle;
- (float) sliceWidth;
- (CGAffineTransform) renderTransformFromLogicalTransform:(CGAffineTransform)xform reverse:(BOOL)reverse;
- (void) buildSlicesEven;
- (void) buildSlicesOdd;
- (void) createWheelRender;
- (void) createCenterButton;
- (float) distFromCenter:(CGPoint)point;
- (void) refreshSliceViewDidSelectWithDelay:(NSTimeInterval)delay;
- (void) refreshSliceViewDidBeginTouchAnimated:(BOOL)animated;
- (void) refreshSliceTitles;
- (void) didPressCenterButton:(id)sender;
@end

@implementation KnobControl
@synthesize numSlices = _numSlices;
@synthesize slices = _slices;
@synthesize container = _container;
@synthesize selectedSlice = _selectedSlice;
@synthesize centerButton;
@synthesize circle;
@synthesize delegate = _delegate;

- (id)initWithFrame:(CGRect)frame delegate:(NSObject<KnobProtocol>*)delegate
{
    self = [super initWithFrame:frame];
    if (self) 
    {
        self.delegate = delegate;
        _numSlices = [self.delegate numItemsInKnob:self];
        _logicalTransform = CGAffineTransformIdentity;
        _selectedSlice = 0;
        _isLocked = NO;
        
        [self createWheelRender];
        [self createCenterButton];
        [self refreshSliceTitles];
        
        // initial refresh of sliceview
        [self refreshSliceViewDidSelectWithDelay:0.0f];
    }
    return self;
}

- (void) dealloc
{
    NSLog(@"KnobControl dealloc");
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
        
    float containerRadius = kKnobRenderFrac * self.bounds.size.width;
    CGRect containerRect = CGRectMake(0.5f * (self.bounds.size.width - containerRadius),
                                   0.5f * (self.bounds.size.width - containerRadius),
                                   containerRadius, containerRadius);
    _container = [[UIView alloc] initWithFrame:containerRect];
    
    CGRect circleInContainerRect = CGRectMake(-containerRect.origin.x, -containerRect.origin.y,
                                              self.bounds.size.width, self.bounds.size.height);
    self.circle = [[CircleView alloc] initWithFrame:circleInContainerRect borderFrac:kKnobRenderFrac
                                        borderWidth:kKnobBorderWidth
                                        borderColor:[UIColor redColor]];
    [self.container addSubview:[self circle]];
    
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
    
    unsigned int sliceIndex = 0;
    for(KnobSlice* curSlice in self.slices)
    {
        [self.container addSubview:[curSlice view]];
        
        // setup decal
        UIImage* decalImage = [self.delegate knob:self decalImageAtIndex:sliceIndex];
        [curSlice.decal setImage:decalImage];
        [curSlice.decal setAlpha:0.35f];
        ++sliceIndex;
    }
    
    self.container.transform = [self renderTransformFromLogicalTransform:_logicalTransform reverse:NO];
    self.container.userInteractionEnabled = NO;
    [self addSubview:[self container]];    

}

- (void) createCenterButton
{
    self.centerButton = [UIButton buttonWithType:UIButtonTypeCustom];
    float parentWidth = self.bounds.size.width;
    float centerWidth = parentWidth * kKnobButtonWidth;
    float parentHeight = self.bounds.size.height;
    float centerHeight = parentHeight * kKnobButtonHeight;
    CGRect centerRect = CGRectMake(0.5f * (parentWidth - centerWidth), 0.5f * (parentHeight - centerHeight),
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

- (void) refreshSliceViewDidSelectWithDelay:(NSTimeInterval)delay
{
    // make selected slice bigger
    unsigned int sliceIndex = 0;
    for(KnobSlice* cur in _slices)
    {
        //if([self selectedSlice] == sliceIndex)
        {
            [UIView animateWithDuration:0.2f
                                  delay:delay
                                options:UIViewAnimationCurveEaseInOut
                             animations:^(void){
                                 [cur useBigTextWithColor:[UIColor whiteColor]];
                             }
                             completion:nil];
        }
        if([self selectedSlice] != sliceIndex)
        {
            [cur.view setHidden:YES];
        }
        ++sliceIndex;
    }
    
    UIColor* knobColor = [self.delegate knob:self colorAtIndex:[self selectedSlice]];
    UIColor* borderColor = [self.delegate knob:self borderColorAtIndex:[self selectedSlice]];
    [UIView animateWithDuration:0.2f
                          delay:delay
                        options:UIViewAnimationCurveEaseInOut
                     animations:^(void){
                         self.circle.borderCircle.backgroundColor = knobColor;
                         self.circle.coloredView.layer.shadowColor = knobColor.CGColor;
                         self.circle.layer.borderColor = borderColor.CGColor;
                         [self.circle setAlpha:1.0f];
                     }
                     completion:nil];
    [self.circle showBigBorder];
}

- (void) refreshSliceViewDidBeginTouchAnimated:(BOOL)animated
{
    // unhide all slices and make them the same size
    unsigned int sliceIndex = 0;
    for(KnobSlice* cur in _slices)
    {
        if(animated)
        {
            UIColor* color = [self.delegate knob:self colorAtIndex:sliceIndex];
            UIColor* borderColor = [self.delegate knob:self borderColorAtIndex:sliceIndex];
            [UIView animateWithDuration:0.2f
                             animations:^(void){
                                 [cur usePopoutWithColor:color borderColor:borderColor];
                             }
                             completion:nil];
        }
        [cur.view setHidden:NO];
        ++sliceIndex;
    }

    if(animated)
    {
        [UIView animateWithDuration:0.2f
                         animations:^(void){
                             self.circle.borderCircle.backgroundColor = [UIColor grayColor];
                             self.circle.coloredView.layer.shadowColor = [UIColor grayColor].CGColor;
                             self.circle.layer.borderColor = [UIColor darkGrayColor].CGColor;
                             [self.circle setAlpha:0.2f];
                         }
                         completion:nil];
    }
    [self.circle showSmallBorder];
}

- (void) refreshSliceTitles
{
    unsigned int sliceCount = 0;
    for(KnobSlice* cur in [self slices])
    {
        [cur setText:[self.delegate knob:self titleAtIndex:sliceCount]];
        ++sliceCount;
    }
}

#pragma mark - UIControl

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event 
{
    BOOL beginTracking = NO;
    
    if(![self isLocked])
    {
        CGPoint touchPoint = [touch locationInView:self];
        //NSLog(@"touchPoint x %f (%f)", touchPoint.x, touchPoint.x / self.bounds.size.width);
        
        // only allow Knob rotation to begin when user touches left or right side of the Knob
        float leftx = self.bounds.size.width * kKnobRotateBeginX;
        float rightx = self.bounds.size.width * (1.0f - kKnobRotateBeginX);
        if((touchPoint.x <= leftx) || (touchPoint.x >= rightx))
        {
            float dist = [self distFromCenter:touchPoint];
            float minDist = self.bounds.size.width * 0.5f * kKnobDragFrac;
            float maxDist = self.bounds.size.width * 0.5f;
            if((minDist <= dist) && (dist <= maxDist))
            {
                // start out with the next index (either to the left or right)
                unsigned int beginIndex = self.selectedSlice;
                if(touchPoint.x <= leftx)
                {
                    // start one slot on the left
                    if(0 == beginIndex)
                    {
                        beginIndex = self.numSlices - 1;
                    }
                    else
                    {
                        beginIndex -= 1;
                    }
                    [self.delegate knobDidPressLeft];
                }
                else
                {
                    // one slot on the right
                    beginIndex++;
                    if([self numSlices] <= beginIndex)
                    {
                        beginIndex = 0;
                    }
                    [self.delegate knobDidPressRight];
                }
                [self beginWithSliceIndex:beginIndex animated:YES];

                // angle at start
                float dx = touchPoint.x - self.container.center.x;
                float dy = touchPoint.y - self.container.center.y;
                _deltaAngle = atan2(dy,dx);
                
                // transform at start
                _startTransform = _logicalTransform;
                beginTracking = YES;
                
                [self refreshSliceViewDidBeginTouchAnimated:YES];
            }
        }
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
                
                // Play sound
                [[SoundManager getInstance] playClip:@"Pog_SFX_Nav_Scroll"];
                break;
            }
        }
        else if ((radians > cur.minAngle) && (radians < cur.maxAngle)) 
        {
            newVal = radians - cur.midAngle;
            self.selectedSlice = index;
            
            // Play sound
            [[SoundManager getInstance] playClip:@"Pog_SFX_Nav_Scroll"];
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
    
    [self refreshSliceViewDidSelectWithDelay:0.0f];
}

- (void) gotoSliceIndex:(unsigned int)index animated:(BOOL)isAnimated
{
    if(index < [self.slices count])
    {
        [self refreshSliceViewDidBeginTouchAnimated:isAnimated];
        KnobSlice* cur = [self.slices objectAtIndex:index];
        self.selectedSlice = index;
        CGFloat radians = atan2f(_logicalTransform.b, _logicalTransform.a);
        CGFloat rot = radians - cur.midAngle;
        
        if(isAnimated)
        {
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration:0.2];
            CGAffineTransform t = CGAffineTransformRotate(_logicalTransform, -rot);
            _logicalTransform = t;
            self.container.transform = [self renderTransformFromLogicalTransform:_logicalTransform reverse:NO];
            [UIView commitAnimations];
            [self refreshSliceViewDidSelectWithDelay:0.2f];
        }
        else
        {
            CGAffineTransform t = CGAffineTransformRotate(_logicalTransform, -rot);
            _logicalTransform = t;
            self.container.transform = [self renderTransformFromLogicalTransform:_logicalTransform reverse:NO];
            [self refreshSliceViewDidSelectWithDelay:0.0f];
        }
    }
}

- (void) beginWithSliceIndex:(unsigned int)index animated:(BOOL)animated
{
    if(index < [self.slices count])
    {
        [self refreshSliceViewDidBeginTouchAnimated:animated];
        
        KnobSlice* cur = [self.slices objectAtIndex:index];
        self.selectedSlice = index;
        CGFloat radians = atan2f(_logicalTransform.b, _logicalTransform.a);
        CGFloat rot = radians - cur.midAngle;
        
        if(animated)
        {
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration:0.2];
            CGAffineTransform t = CGAffineTransformRotate(_logicalTransform, -rot);
            _logicalTransform = t;
            self.container.transform = [self renderTransformFromLogicalTransform:_logicalTransform reverse:NO];
            [UIView commitAnimations];
        }
        else
        {
            CGAffineTransform t = CGAffineTransformRotate(_logicalTransform, -rot);
            _logicalTransform = t;
            self.container.transform = [self renderTransformFromLogicalTransform:_logicalTransform reverse:NO];
        }
    }
}

- (void) setLocked:(BOOL)locked
{
    _isLocked = locked;
}

- (BOOL) isLocked
{
    return _isLocked;
}

#pragma mark - button actions
- (void) didPressCenterButton:(id)sender
{
    [self.delegate didPressKnobAtIndex:[self selectedSlice]];
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
