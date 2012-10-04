//
//  TradePost.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "Player.h"
#import "TradePost.h"
#import "TradePostMgr.h"
#import "TradePostAnnotationView.h"
#import "GameNotes.h"
#import "GameManager.h"

@interface TradePost()
{
    __weak TradePostAnnotationView* _flyerAtPostObserver;
}
@property (nonatomic,weak) TradePostAnnotationView* flyerAtPostObserver;
@end

@implementation TradePost
@synthesize postId = _postId;
@synthesize itemId = _itemId;
@synthesize supplyLevel = _supplyLevel;
@synthesize imgPath = _imgPath;
@synthesize supplyMaxLevel = _supplyMaxLevel;
@synthesize beacontime = _beacontime;
@synthesize delegate = _delegate;
@synthesize creationDate = _creationDate;
@synthesize flyerAtPostObserver = _flyerAtPostObserver;

- (id) init
{
    self = [super init];
    if(self)
    {
        _flyerAtPost = nil;
        _creationDate = [NSDate date];
        _flyerAtPostObserver = nil;
    }
    return self;
}

- (void) dealloc
{
    if([self flyerAtPostObserver])
    {
        [self removeFlyerAtPostObserver:[self flyerAtPostObserver]];
    }
}

// sort from low to high supply level
// secondarily, sort from earliest to latest creationDates
- (NSComparisonResult) compareSupplyThenDate:(TradePost*)theOtherPost
{
    NSComparisonResult result = NSOrderedSame;
    if([self supplyLevel] < [theOtherPost supplyLevel])
    {
        result = NSOrderedAscending;
    }
    else if([self supplyLevel] > [theOtherPost supplyLevel])
    {
        result = NSOrderedDescending;
    }
    else
    {
        result = NSOrderedSame;
    }

    // if result is the same, break ties with creation date
    if(result == NSOrderedSame)
    {
        NSDate* earlierDate = [self.creationDate earlierDate:[theOtherPost creationDate]];
        if([earlierDate isEqualToDate:[self creationDate]])
        {
            result = NSOrderedAscending;
        }
        else if([earlierDate isEqualToDate:[theOtherPost creationDate]])
        {
            result = NSOrderedDescending;
        }
    }
    
    return result;
}

- (void) addFlyerAtPostObserver:(TradePostAnnotationView*)observerView
{
    if([self flyerAtPostObserver])
    {
        [self removeFlyerAtPostObserver:[self flyerAtPostObserver]];
    }
    [self addObserver:observerView forKeyPath:kKeyFlyerAtPost options:0 context:nil];
    self.flyerAtPostObserver = observerView;
}

- (void) removeFlyerAtPostObserver:(TradePostAnnotationView*)observerView
{
    if([self.flyerAtPostObserver isEqual:observerView])
    {
        [self removeObserver:observerView forKeyPath:kKeyFlyerAtPost];
        self.flyerAtPostObserver = nil;
    }
}

#pragma mark - trade
- (void) deductNumItems:(unsigned int)num
{
    unsigned int numToSub = MIN([self supplyLevel], num);
    self.supplyLevel -= numToSub;
}

#pragma mark - getters/setters
- (CLLocationCoordinate2D) coord
{
    return _coord;
}

- (void) setCoord:(CLLocationCoordinate2D)coord
{
    _coord = coord;
}

- (Flyer*) flyerAtPost
{
    return _flyerAtPost;
}

- (void) setFlyerAtPost:(Flyer *)flyerAtPost
{
    _flyerAtPost = flyerAtPost;
    // HACK (force refresh MyTradePost; for some reason, MyTradePost
    // fails to redraw regardless of any changes on its annotation-view unless forced)
    [[GameManager getInstance] reAddOnMapIfMyPost:self];
    // HACK
}

#pragma mark - MKAnnotation delegate
- (CLLocationCoordinate2D) coordinate
{
    return [self coord];
}

- (void) setCoordinate:(CLLocationCoordinate2D)newCoordinate
{
    self.coord = newCoordinate;
}

#pragma mark - MapAnnotationProtocol
- (TradePostAnnotationView*) getAnnotationViewInstance:(MKMapView *)mapView
{
    TradePostAnnotationView* annotationView = (TradePostAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:kTradePostAnnotationViewReuseId];
    if(annotationView)
    {
        annotationView.annotation = self;
    }
    else
    {
        annotationView = [[TradePostAnnotationView alloc] initWithAnnotation:self];
    }
    
    // set myself up to observe flyerAtPost
    [self addFlyerAtPostObserver:annotationView];

    return annotationView;
}

- (MKAnnotationView*) annotationViewInMap:(MKMapView *)mapView
{
    // This function should never be called in the base class.
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

@end
