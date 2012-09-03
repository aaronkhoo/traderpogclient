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
#import "GameManager.h"
#import "PogUIUtility.h"

NSString* const kFlyerAnnotationViewReuseId = @"FlyerAnnotationView";
static NSString* const kFlyerTransformKey = @"transform";
static NSString* const kKeyFlyerIsAtOwnPost = @"isAtOwnPost";
static NSString* const kKeyFlyerMetersToDest = @"metersToDest";

static const float kFlyerTimerOriginOffset = 30.0f;
static const float kFlyerTimerSizeWidth = 80.0f;
static const float kFlyerTimerSizeHeight = 20.0f;
static const float kFlyerAnnotViewSize = 50.0f;
static const float kFlyerAnnotContentSize = 80.0f;

@interface FlyerAnnotationView ()
{
    FlyerCallout* _calloutAnnotation;
    UIImageView* _imageView;
    UIView* _contentView;
    UILabel* _timerLabel;
}
@property (nonatomic,strong) UIImageView* imageView;
@property (nonatomic,strong) UIView* contentView;
@property (nonatomic,strong) UILabel* timerLabel;
- (CGRect) timerFrameForFlyerTransform:(CGAffineTransform)transform;
- (void) createTimerLabel;
@end

@implementation FlyerAnnotationView
@synthesize imageView = _imageView;
@synthesize contentView = _contentView;
@synthesize timerLabel = _timerLabel;
- (id) initWithAnnotation:(NSObject<MKAnnotation>*)annotation
{
    self = [super initWithAnnotation:annotation reuseIdentifier:kFlyerAnnotationViewReuseId];
    if(self)
    {
        [self setBackgroundColor:[UIColor blueColor]];
        
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
        
        // setup tradepost image
        CGRect imageFrame = contentFrame;
        imageFrame.origin = CGPointMake(0.0f, 0.0f);
        UIImage *annotationImage = [UIImage imageNamed:@"Flyer.png"];
        self.opaque = NO;
        
        self.imageView = [[UIImageView alloc] initWithFrame:imageFrame];
        [self.imageView setBackgroundColor:[UIColor colorWithWhite:0.5f alpha:0.5f]];
        [self.imageView setImage:annotationImage];
        [self.contentView addSubview:[self imageView]];
        
        [self addSubview:[self contentView]];
        
        // timer label
        [self createTimerLabel];
        
        _calloutAnnotation = nil;
        
        // observe flyer transform and isAtOwnPost
        [annotation addObserver:self forKeyPath:kFlyerTransformKey options:0 context:nil];
        [annotation addObserver:self forKeyPath:kKeyFlyerIsAtOwnPost options:0 context:nil];
        [annotation addObserver:self forKeyPath:kKeyFlyerMetersToDest options:0 context:nil];
    }
    return self;
}

- (void) dealloc
{
    Flyer* flyer = (Flyer*)[self annotation];
    [flyer removeObserver:self forKeyPath:kKeyFlyerMetersToDest];
    [flyer removeObserver:self forKeyPath:kKeyFlyerIsAtOwnPost];
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
        else if([keyPath isEqualToString:kKeyFlyerIsAtOwnPost])
        {
            if([flyer isAtOwnPost])
            {
                // disable touch for Flyer when it is at own post
                // own-post's callout will handle interaction with the user
                [self setEnabled:NO];
            }
            else
            {
                [self setEnabled:YES];
            }
        }
        else if([keyPath isEqualToString:kKeyFlyerMetersToDest])
        {
            NSTimeInterval timeTillDest = [flyer timeTillDest];
            NSString* timerString = [PogUIUtility stringFromTimeInterval:timeTillDest];
            [self.timerLabel setText:timerString];
        }
    }
}

- (void) setRenderTransform:(CGAffineTransform)transform
{
    [self.imageView setTransform:transform];
    self.timerLabel.frame = [self timerFrameForFlyerTransform:transform];
}

#pragma mark - internal methods
- (CGRect) timerFrameForFlyerTransform:(CGAffineTransform)transform
{
    CGPoint center = CGPointMake(self.contentView.frame.size.width * 0.5f,
                                 self.contentView.frame.size.height * 0.5f);
    CGPoint up = CGPointMake(0.0f, 1.0f);
    CGPoint vec = CGPointApplyAffineTransform(up, transform);
    CGPoint origin = CGPointMake(center.x + (kFlyerTimerOriginOffset * vec.x),
                                 center.y + (kFlyerTimerOriginOffset * vec.y));
    CGRect result = CGRectMake(origin.x, origin.y, kFlyerTimerSizeWidth, kFlyerTimerSizeHeight);
    return result;
}

- (void) createTimerLabel
{
    self.timerLabel = [[UILabel alloc] initWithFrame:[self timerFrameForFlyerTransform:CGAffineTransformIdentity]];
    [self.timerLabel setFont:[UIFont fontWithName:@"Marker Felt" size:10.0f]];
    [self.timerLabel setText:@"Hello"];
    [self.contentView addSubview:[self timerLabel]];
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
