//
//  Flyer.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/21/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "AFClientManager.h"
#import "Flyer.h"
#import "TradePost.h"
#import "FlightPathOverlay.h"
#import "FlyerAnnotation.h"
#import "TradePostMgr.h"
#import "Player.h"
#import "PogUIUtility.h"
#import "MKMapView+Pog.h"

static const float kFlyerDefaultSpeedMetersPerSec = 100.0f;
static NSString* const kKeyFlyerId = @"flyer_info_id";

@interface Flyer ()
{
    // flight enroute processing
    NSDate* _departureDate;
    CLLocationCoordinate2D _srcCoord;
    CLLocationCoordinate2D _destCoord;
    CLLocationCoordinate2D _renderCoord;    // this is always a little ahead of the current sim location
    CLLocationDistance _metersToDest;
}
@property (nonatomic,strong) NSDate* departureDate;
@property (nonatomic) CLLocationCoordinate2D srcCoord;
@property (nonatomic) CLLocationCoordinate2D destCoord;

- (CLLocationCoordinate2D) flyerCoordinateAtTimeSinceDeparture:(NSTimeInterval)elapsed;
- (CLLocationCoordinate2D) flyerCoordinateNow;
- (CLLocationCoordinate2D) flyerCoordinateAtTimeAhead:(NSTimeInterval)timeAhead;
@end

@implementation Flyer
@synthesize flyerId = _flyerId;
@synthesize flightSpeed = _flightSpeed;
@synthesize curPostId = _curPostId;
@synthesize nextPostId = _nextPostId;
@synthesize flightPathRender = _flightPathRender;
@synthesize annotation = _annotation;
@synthesize coord = _coord;
@synthesize departureDate = _departureDate;
@synthesize srcCoord = _srcCoord;
@synthesize destCoord = _destCoord;
@synthesize transform = _transform;
@synthesize delegate = _delegate;

- (id) initAtPost:(TradePost*)tradePost
{
    self = [super init];
    if(self)
    {
        _flightSpeed = kFlyerDefaultSpeedMetersPerSec;
        _curPostId = [tradePost postId];
        _nextPostId = nil;
        _flightPathRender = nil;
        _annotation = nil;
        _coord = [tradePost coord];
        _departureDate = nil;
        _srcCoord = _coord;
        _destCoord = _coord;
        _metersToDest = 0.0;
        _transform = CGAffineTransformIdentity;
    }
    return self;
}

- (id) initWithPostAndFlyerId:(TradePost*)tradePost, NSString* flyerId
{
    self = [super init];
    if(self)
    {
        _flyerId = flyerId;
        _coord = [tradePost coord];
        
        _flightSpeed = kFlyerDefaultSpeedMetersPerSec;
        _curPostId = [tradePost postId];
        _nextPostId = nil;
        _flightPathRender = nil;
        _annotation = nil;
        _departureDate = nil;
        _srcCoord = _coord;
        _destCoord = _coord;
        _metersToDest = 0.0;
        _transform = CGAffineTransformIdentity;

    }
    return self;
}

- (id) initWithDictionary:(NSDictionary*)dict
{
    self = [super init];
    if(self)
    {
        _annotation = nil;
        
        _flyerId = [NSString stringWithFormat:@"%d", [[dict valueForKeyPath:@"flyer_info_id"] integerValue]];
        
        NSArray* paths_array = [dict valueForKeyPath:@"flyer_paths"];
        NSDictionary* path_dict = [paths_array objectAtIndex:0];
        _curPostId = [NSString stringWithFormat:@"%d", [[path_dict valueForKeyPath:@"post1"] integerValue]];
        if (_curPostId == nil)
        {
            // No post ID, so it must be stored in the longitude/latitude values
            _srcCoord.latitude = [[dict valueForKeyPath:@"latitude1"] doubleValue];
            _srcCoord.longitude = [[dict valueForKeyPath:@"longitude1"] doubleValue];
        }
        else
        {
            _srcCoord = [[[TradePostMgr getInstance] getTradePostWithId:_curPostId] coord];
        }
        _nextPostId = [NSString stringWithFormat:@"%d", [[path_dict valueForKeyPath:@"post2"] integerValue]];;
        if ([_curPostId compare:_nextPostId] == NSOrderedSame)
        {
            // If the server indicated curPostId and nextPostId are the same,
            // then the flyer is at its original position, which means it isn't moving
            _nextPostId = nil;
            _departureDate = nil;
        }
        else
        {
            if (_nextPostId == nil)
            {
                // No post ID, so it must be stored in the longitude/latitude values
                _destCoord.latitude = [[dict valueForKeyPath:@"latitude2"] doubleValue];
                _destCoord.longitude = [[dict valueForKeyPath:@"longitude2"] doubleValue];
            }
            else
            {
                _destCoord = [[[TradePostMgr getInstance] getTradePostWithId:_nextPostId] coord];
            }
        }
        
        // TODO: Not sure this is the correct behavior
        _coord = _srcCoord;
        _flightPathRender = nil;
        _annotation = nil;
        _metersToDest = 0.0;
        _transform = CGAffineTransformIdentity;
    }
    return self;
}

- (void) createNewUserFlyerOnServer
{
    // post parameters
    NSString *userFlyerPath = [NSString stringWithFormat:@"users/%d/user_flyers", [[Player getInstance] id]];
    NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                _flyerId, kKeyFlyerId,
                                nil];
    
    // make a post request
    AFHTTPClient* httpClient = [[AFClientManager sharedInstance] traderPog];
    [httpClient setDefaultHeader:@"Init-Post-Id" value:_curPostId];
    [httpClient postPath:userFlyerPath
              parameters:parameters
                 success:^(AFHTTPRequestOperation *operation, id responseObject){
                     [self.delegate didCompleteHttpCallback:kFlyer_CreateNewFlyer, TRUE];
                 }
                 failure:^(AFHTTPRequestOperation* operation, NSError* error){
                     UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Server Failure"
                                                                       message:@"Unable to create flyer. Please try again later."
                                                                      delegate:nil
                                                             cancelButtonTitle:@"OK"
                                                             otherButtonTitles:nil];
                     
                     [message show];
                     [self.delegate didCompleteHttpCallback:kFlyer_CreateNewFlyer, FALSE];
                 }
     ];
    [httpClient setDefaultHeader:@"Init-Post-Id" value:nil];
}

#pragma mark - flight public
- (void) departForPostId:(NSString *)postId
{
    if((![postId isEqualToString:[self curPostId]]) &&
       (![self nextPostId]))
    {
        self.nextPostId = postId;
        self.departureDate = [NSDate date];
        
        // create renderer
        self.srcCoord = [[[TradePostMgr getInstance] getTradePostWithId:[self curPostId]] coord];
        self.destCoord = [[[TradePostMgr getInstance] getTradePostWithId:[self nextPostId]] coord];
        self.flightPathRender = [[FlightPathOverlay alloc] initWithSrcCoord:[self srcCoord] destCoord:[self destCoord]];
        
        // flyer zero-angle is up; so, need to offset it by 90 degrees
        float angle = [MKMapView angleBetweenCoordinateA:[self srcCoord] coordinateB:[self destCoord]];
        angle += M_PI_2;
        _transform = CGAffineTransformMakeRotation(angle);
    }
}

- (void) updateAtDate:(NSDate *)currentTime
{
    if([self nextPostId])
    {
        // enroute
        CLLocationCoordinate2D curCoord = [self flyerCoordinateNow];
        self.coord = curCoord;
        if([self annotation])
        {
            [self.annotation setCoordinate:curCoord];
            _renderCoord = [self flyerCoordinateAtTimeAhead:1.0f/8.0f];
            /*
            FlyerAnnotationView* annotView = nil;
            if(_flyerAnnotView && ([_flyerAnnotView annotation] == self))
            {
                annotView = _flyerAnnotView;
            } 
             */
        }
        
        if([self flightPathRender])
        {
            [self.flightPathRender setCurCoord:curCoord];
        }
        
        NSTimeInterval elapsed = -[self.departureDate timeIntervalSinceNow];
        CLLocationDistance routeDist = metersDistance([self srcCoord], [self destCoord]);
        _metersToDest = routeDist - (elapsed * self.flightSpeed);
        if(_metersToDest <= 0.0)
        {
            _metersToDest = 0.0;
            
            // arrived
            self.curPostId = [self nextPostId];
            self.nextPostId = nil;
//            [self didArriveAtPost:[self destPostId]];
   
            /*
            NSString* timeString = [PogUIUtility stringFromTimeInterval:0.0];
            UILabel* timeLabel = (UILabel*)[_timeTillDestView.subviews objectAtIndex:0];
            [timeLabel setText:timeString];
            
            if(annotView)
            {
                [annotView hideEnrouteTimer];
            }
             */
        }
        else 
        {
            /*
            NSTimeInterval timeRemaining = [self timeTillDest] + 1.0;   // add 1 second for the benefits of the countdown display
            NSString* timeString = [PogUIUtility stringFromTimeInterval:timeRemaining];
            UILabel* timeLabel = (UILabel*)[_timeTillDestView.subviews objectAtIndex:0];
            [timeLabel setText:timeString];
            
            if(annotView)
            {
                NSTimeInterval timeRemaining = [self timeTillDest] + 1.0;   // add 1 second for the benefits of the countdown display
                [annotView refreshEnrouteTimerWithTime:timeRemaining];
            }
             */
        }
    }
}

#pragma mark - flight private
static CLLocationDistance metersDistance(CLLocationCoordinate2D originCoord, CLLocationCoordinate2D destCoord)
{
    MKMapPoint origin = MKMapPointForCoordinate(originCoord);
    MKMapPoint dest = MKMapPointForCoordinate(destCoord);
    CLLocationDistance dist = MKMetersBetweenMapPoints(origin, dest);
    
    return dist;
}

- (CLLocationCoordinate2D) flyerCoordinateAtTimeSinceDeparture:(NSTimeInterval)elapsed
{
    CLLocationCoordinate2D coordNow = [self coord];
    if([self nextPostId])
    {
        CLLocationDistance distMeters = metersDistance([self srcCoord], [self destCoord]);
        MKMapPoint srcPoint = MKMapPointForCoordinate([self srcCoord]);
        MKMapPoint destPoint = MKMapPointForCoordinate([self destCoord]);
        MKMapPoint routeVec = MKMapPointMake(destPoint.x - srcPoint.x, destPoint.y - srcPoint.y);
        double distPoints = sqrt((routeVec.x * routeVec.x) + (routeVec.y * routeVec.y));
        MKMapPoint routeVecNormalized = MKMapPointMake(routeVec.x / distPoints, routeVec.y / distPoints);
        
        CLLocationDistance distTraveledMeters = [self flightSpeed] * elapsed;
        if(distTraveledMeters < distMeters)
        {
            double distTraveledPoints = (distTraveledMeters / distMeters) * distPoints;
            MKMapPoint curPoint = MKMapPointMake(srcPoint.x + (distTraveledPoints * routeVecNormalized.x),
                                                 srcPoint.y + (distTraveledPoints * routeVecNormalized.y));
            coordNow = MKCoordinateForMapPoint(curPoint);
        }
        else 
        {
            // flyer is already at destination, just return the destination coordinate
            coordNow = [self destCoord];
        }
    }
    return coordNow;    
}

- (CLLocationCoordinate2D) flyerCoordinateNow
{
    NSTimeInterval elapsed = -[self.departureDate timeIntervalSinceNow];
    CLLocationCoordinate2D coordNow = [self flyerCoordinateAtTimeSinceDeparture:elapsed];
    return coordNow;
}

- (CLLocationCoordinate2D) flyerCoordinateAtTimeAhead:(NSTimeInterval)timeAhead
{
    NSTimeInterval elapsed = -[self.departureDate timeIntervalSinceNow];
    elapsed += timeAhead;
    CLLocationCoordinate2D coordNow = [self flyerCoordinateAtTimeSinceDeparture:elapsed];
    return coordNow;
}


@end
