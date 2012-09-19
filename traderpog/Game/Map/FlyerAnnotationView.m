//
//  FlyerAnnotationView.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/22/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "FlyerAnnotationView.h"
#import "Flyer.h"
#import "FlyerCallout.h"
#import "FlyerPath.h"
#import "GameManager.h"
#import "PogUIUtility.h"
#import "CircleBarView.h"
#import "Clockface.h"

NSString* const kFlyerAnnotationViewReuseId = @"FlyerAnnotationView";
static NSString* const kFlyerTransformKey = @"transform";
static NSString* const kKeyFlyerMetersToDest = @"metersToDest";
static NSString* const kKeyFlyerState = @"state";

static const float kFlyerTimerOriginOffsetX = 0.0f;
static const float kFlyerTimerOriginOffsetY = 44.0f;
static const float kFlyerAnnotViewSize = 50.0f;
static const float kFlyerAnnotContentSize = 85.0f;

@interface FlyerAnnotationView ()
{
    FlyerCallout* _calloutAnnotation;
    UIView* _contentView;
    CircleBarView* _countdown;
    Clockface* _countdownClock;
}
@property (nonatomic,strong) UIView* contentView;
@property (nonatomic,strong) CircleBarView* countdown;
- (CGAffineTransform) countdownTransformFromFlyerTransform:(CGAffineTransform)transform;
- (void) createCountdown;
@end

@implementation FlyerAnnotationView
@synthesize imageView = _imageView;
@synthesize imageViewIdentity = _imageViewIdentity;
@synthesize contentView = _contentView;
@synthesize countdown = _countdown;
- (id) initWithAnnotation:(NSObject<MKAnnotation>*)annotation
{
    self = [super initWithAnnotation:annotation reuseIdentifier:kFlyerAnnotationViewReuseId];
    if(self)
    {
        [self setBackgroundColor:[UIColor clearColor]];
        
        // handle our own callout
        self.canShowCallout = NO;
        self.enabled = YES;

        // set size of view
        CGRect myFrame = self.frame;
        myFrame.size =   CGSizeMake(kFlyerAnnotViewSize, kFlyerAnnotViewSize);
        self.frame = myFrame;
        
        CGRect contentFrame = CGRectMake((kFlyerAnnotViewSize - kFlyerAnnotContentSize) * 0.5f,
                                         (kFlyerAnnotViewSize - kFlyerAnnotContentSize) * 0.5f,
                                         kFlyerAnnotContentSize,
                                         kFlyerAnnotContentSize);
        self.contentView = [[UIView alloc] initWithFrame:contentFrame];
        self.opaque = NO;
        
        // setup tradepost image
        CGRect imageOrientedFrame = contentFrame;
        imageOrientedFrame.origin = CGPointMake(0.0f, 0.0f);
        self.imageView = [[UIImageView alloc] initWithFrame:imageOrientedFrame];
        [self.imageView setBackgroundColor:[UIColor clearColor]];
        [self.imageView setHidden:YES];
        [self.contentView addSubview:[self imageView]];
                
        CGRect imageIdentityFrame = contentFrame;
        imageIdentityFrame.origin = CGPointMake(0.0f, -(0.5f * contentFrame.size.height));
        self.imageViewIdentity = [[UIImageView alloc] initWithFrame:imageIdentityFrame];
        [self.imageViewIdentity setBackgroundColor:[UIColor clearColor]];
        [self.imageViewIdentity setHidden:YES];
        
        [self.contentView addSubview:[self imageViewIdentity]];
        [self addSubview:[self contentView]];
        
        // countdown (start out hidden)
        [self createCountdown];
        [self showCountdown:NO];
        
        _calloutAnnotation = nil;
        
        // observe flyer vars
        Flyer* flyer = (Flyer*)annotation;
        [flyer addObserver:self forKeyPath:kFlyerTransformKey options:0 context:nil];
        [flyer addObserver:self forKeyPath:kKeyFlyerMetersToDest options:0 context:nil];
        [flyer addObserver:self forKeyPath:kKeyFlyerState options:0 context:nil];
    }
    return self;
}

- (void) dealloc
{
    Flyer* flyer = (Flyer*)[self annotation];
    [flyer removeObserver:self forKeyPath:kKeyFlyerState];
    [flyer removeObserver:self forKeyPath:kKeyFlyerMetersToDest];
    [flyer removeObserver:self forKeyPath:kFlyerTransformKey];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context
{
    if([object isMemberOfClass:[Flyer class]])
    {
        Flyer* flyer = (Flyer*)object;
        if([keyPath isEqualToString:kFlyerTransformKey])
        {
            [self setRenderTransform:[flyer transform]];
        }
        else if([keyPath isEqualToString:kKeyFlyerMetersToDest])
        {
            // add 1 second as a fake roundup (so that when time is less than 1 second but larger than
            // 0), user would see 1 sec
            NSTimeInterval timeTillDest = [flyer timeTillDest] + 1.0f;
            NSString* timerString = [PogUIUtility stringFromTimeInterval:timeTillDest];
            [self.countdown.label setText:timerString];
        }
        else if([keyPath isEqualToString:kKeyFlyerState])
        {
            // flyer state changed
            [flyer refreshImageInAnnotationView:self];
        }
    }
}

- (void) setRenderTransform:(CGAffineTransform)transform
{
    [self.imageView setTransform:transform];
    [self.countdown setTransform:[self countdownTransformFromFlyerTransform:transform]];
}

- (void) showCountdown:(BOOL)yesNo
{
    if(yesNo)
    {
        [self.countdown setHidden:NO];
        [_countdownClock startAnimating];
        
    }
    else
    {
        [self.countdown setHidden:YES];
        [_countdownClock stopAnimating];
    }
}

- (void) setOrientedImage:(UIImage *)image
{
    [self.imageView setImage:image];
    [self.imageView setHidden:NO];
    [self.imageViewIdentity setHidden:YES];
}

- (void) setImage:(UIImage *)image
{
    [self.imageViewIdentity setImage:image];
    [self.imageViewIdentity setHidden:NO];
    [self.imageView setHidden:YES];
}

#pragma mark - internal methods
- (CGAffineTransform) countdownTransformFromFlyerTransform:(CGAffineTransform)transform
{
    CGPoint up = CGPointMake(kFlyerTimerOriginOffsetX, kFlyerTimerOriginOffsetY);
    CGPoint vec = CGPointApplyAffineTransform(up, transform);
    CGAffineTransform result = CGAffineTransformMakeTranslation(vec.x, vec.y);
    return result;
}

static const float kFlyerCountdownWidth = 64.0f;
static const float kFlyerCountdownHeight = 22.0f;
- (void) createCountdown
{
    // place it in the center of contentView
    CGRect countdownFrame = CGRectMake(self.contentView.frame.size.width * 0.5f,
                                       self.contentView.frame.size.height * 0.5f,
                                       kFlyerCountdownWidth, kFlyerCountdownHeight);
    UIColor* color = [UIColor colorWithRed:237.0f/255.0f
                                     green:28.0f/255.0f
                                      blue:36.0f/255.0f
                                     alpha:1.0f];
    self.countdown = [[CircleBarView alloc] initWithFrame:countdownFrame
                                                    color:color
                                                textColor:[UIColor whiteColor]
                                              borderColor:color
                                              borderWidth:1.5f
                                                 textSize:15.0f
                                            barHeightFrac:0.7f
                                           hasRoundCorner:NO];
    
    _countdownClock = [[Clockface alloc] initWithFrame:self.countdown.leftCircle.bounds];
    [self.countdown.leftCircle addSubview:_countdownClock];
    [self.contentView addSubview:[self countdown]];
}

#pragma mark - MKAnnotationView
- (void)setAnnotation:(id<MKAnnotation>)annotation
{
    if(_calloutAnnotation)
    {
        [_calloutAnnotation setCoordinate:annotation.coordinate];
    }
    [super setAnnotation:annotation];
    //self.enabled = YES;
}

#pragma mark - PogMapAnnotationViewProtocol
- (void)didSelectAnnotationViewInMap:(MKMapView*) mapView;
{   
    if(!_calloutAnnotation)
    {
        if([[GameManager getInstance] canShowMapAnnotationCallout])
        {
            Flyer* flyer = (Flyer*) [self annotation];
            if(![[flyer path] isEnroute])
            {
                // show Flyer Callout if not enroute
                _calloutAnnotation = [[FlyerCallout alloc] initWithFlyer:flyer];
                _calloutAnnotation.parentAnnotationView = self;
                [mapView addAnnotation:_calloutAnnotation];
            }
        }
        else
        {
            // disallow callout
            [mapView deselectAnnotation:[self annotation] animated:NO];
        }
    }
}

- (void)didDeselectAnnotationViewInMap:(MKMapView*) mapView;
{
    if(_calloutAnnotation)
    {
        [mapView removeAnnotation:_calloutAnnotation];
        _calloutAnnotation = nil;
    }
}



@end
