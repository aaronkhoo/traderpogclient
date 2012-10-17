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

@implementation TradePost
@synthesize postId = _postId;
@synthesize itemId = _itemId;
@synthesize supplyLevel = _supplyLevel;
@synthesize imgPath = _imgPath;
@synthesize supplyMaxLevel = _supplyMaxLevel;
@synthesize beacontime = _beacontime;
@synthesize delegate = _delegate;
@synthesize creationDate = _creationDate;
@synthesize gameEvent = _gameEvent;

- (id) init
{
    self = [super init];
    if(self)
    {
        _flyerAtPost = nil;
        _creationDate = [NSDate date];
        _gameEvent = nil;
    }
    return self;
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
    [[NSNotificationCenter defaultCenter] postNotificationName:kGameNotePostFlyerChanged
                                                        object:self];
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
