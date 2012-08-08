//
//  Flyer.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/21/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "AFClientManager.h"
#import "Flyer.h"
#import "FlyerType.h"
#import "FlyerTypes.h"
#import "FlightPathOverlay.h"
#import "FlyerAnnotation.h"
#import "GameManager.h"
#import "TradePost.h"
#import "TradePostMgr.h"
#import "Player.h"
#import "PogUIUtility.h"
#import "MKMapView+Pog.h"

static const float kFlyerDefaultSpeedMetersPerSec = 100.0f;
static NSString* const kKeyUserFlyerId = @"id";
static NSString* const kKeyFlyerPathId = @"id";
static NSString* const kKeyDepartureDate = @"created_at";
static NSString* const kKeyFlyerId = @"flyer_info_id";
static NSString* const kKeyPost1 = @"post1";
static NSString* const kKeyPost2 = @"post2";
static NSString* const kKeyLongitude1 = @"longitude1";
static NSString* const kKeyLatitude1 = @"latitude1";
static NSString* const kKeyLongitude2 = @"longitude2";
static NSString* const kKeyLatitude2 = @"latitude2";
static NSString* const kKeyStorms= @"storms";
static NSString* const kKeyStormed= @"stormed";
static NSString* const kKeyDone = @"done";

@interface Flyer ()
{
    // temp variable for storing next flight path before it is confirmed by server
    BOOL _creatingNextFlyerPath;
    NSString* _projectedNextPost;
    
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

- (id) initWithPostAndFlyer:(TradePost*)tradePost, NSInteger flyerTypeIndex
{
    self = [super init];
    if(self)
    {
        _creatingNextFlyerPath = FALSE;
        _projectedNextPost = nil;
        
        _flyerTypeIndex = flyerTypeIndex;
        _coord = [tradePost coord];
        _flyerPathId = nil;
        
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
        _creatingNextFlyerPath = FALSE;
        _projectedNextPost = nil;
        
        _userFlyerId = [dict valueForKeyPath:kKeyUserFlyerId];
        
        NSString* flyerTypeId = [NSString stringWithFormat:@"%d", [[dict valueForKeyPath:@"flyer_info_id"] integerValue]];
        _flyerTypeIndex = [[FlyerTypes getInstance] getFlyerIndexById:flyerTypeId];
        
        NSArray* paths_array = [dict valueForKeyPath:@"flyer_paths"];
        NSDictionary* path_dict = [paths_array objectAtIndex:0];
        id obj = [path_dict valueForKeyPath:@"post1"];
        if ((NSNull *)obj == [NSNull null])
        {
            // No post ID, so it must be stored in the longitude/latitude values
            _srcCoord.latitude = [[path_dict valueForKeyPath:@"latitude1"] doubleValue];
            _srcCoord.longitude = [[path_dict valueForKeyPath:@"longitude1"] doubleValue];
        }
        else
        {
            _curPostId = [NSString stringWithFormat:@"%d", [obj integerValue]];
            _srcCoord = [[[TradePostMgr getInstance] getTradePostWithId:_curPostId] coord];
        }
        
        obj = [path_dict valueForKeyPath:@"post2"];
        if ((NSNull *)obj == [NSNull null])
        {
            // No post ID, so it must be stored in the longitude/latitude values
            _destCoord.latitude = [[path_dict valueForKeyPath:@"latitude2"] doubleValue];
            _destCoord.longitude = [[path_dict valueForKeyPath:@"longitude2"] doubleValue];
        }
        else
        {
            _nextPostId = [NSString stringWithFormat:@"%d", [obj integerValue]];
            if (_curPostId && [_curPostId compare:_nextPostId] == NSOrderedSame)
            {
                // If the server indicated curPostId and nextPostId are the same,
                // then the flyer is at its original position, which means it isn't moving
                _nextPostId = nil;
                _departureDate = nil;
                _coord = _srcCoord;
            }
            else
            {
                _destCoord = [[[TradePostMgr getInstance] getTradePostWithId:_nextPostId] coord];   
            }
        }
        
        NSString* utcdate = [path_dict valueForKeyPath:kKeyDepartureDate];
        [self storeDepartureDate:utcdate];
        
        // init runtime transient vars
        _coord = [self flyerCoordinateNow];
        _flightPathRender = nil;
        _annotation = nil;
        _metersToDest = 0.0;
        _transform = CGAffineTransformIdentity;

    }
    return self;
}

- (NSInteger) getFlyerSpeed
{
    FlyerType* current  = [[[FlyerTypes getInstance] flyerTypes] objectAtIndex:_flyerTypeIndex];
    return [current speed];
}

- (void) storeDepartureDate:(NSString*)utcdate
{
    // Set up conversion of RFC 3339 time format
    NSDateFormatter *rfc3339DateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    
    [rfc3339DateFormatter setLocale:enUSPOSIXLocale];
    [rfc3339DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    [rfc3339DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    // Convert the RFC 3339 date time string to an NSDate.
    _departureDate= [rfc3339DateFormatter dateFromString:utcdate];
}

- (void) createNewUserFlyerOnServer
{
    // post parameters
    NSString *userFlyerPath = [NSString stringWithFormat:@"users/%d/user_flyers", [[Player getInstance] id]];
    FlyerType* current  = [[[FlyerTypes getInstance] flyerTypes] objectAtIndex:_flyerTypeIndex];
    NSString* flyerId = [current flyerId];
    NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                flyerId, kKeyFlyerId,
                                nil];
    
    // make a post request
    AFHTTPClient* httpClient = [[AFClientManager sharedInstance] traderPog];
    [httpClient setDefaultHeader:@"Init-Post-Id" value:_curPostId];
    [httpClient postPath:userFlyerPath
              parameters:parameters
                 success:^(AFHTTPRequestOperation *operation, id responseObject){
                     _userFlyerId = [responseObject valueForKeyPath:kKeyUserFlyerId];
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

- (NSDictionary*) createParametersForFlyerPath
{
    NSMutableDictionary* parameters = [NSMutableDictionary dictionaryWithCapacity:6];
    
    // Source post
    if (_curPostId)
    {
        TradePost* post1 = [[TradePostMgr getInstance] getTradePostWithId:_curPostId];
        if (post1.isNPCPost)
        {
            CLLocationCoordinate2D location = post1.coord;
            [parameters setValue:[NSNumber numberWithDouble:location.longitude] forKey:kKeyLongitude1];
            [parameters setValue:[NSNumber numberWithDouble:location.latitude] forKey:kKeyLatitude1];
        }
        else
        {
            [parameters setObject:_curPostId forKey:kKeyPost1];
        }
    }
    else
    {
        // This can happen when the source location is retrieved from the server, and was an NPC trade post
        // that didn't exist there, so the only info we have on it are the longitude/latitude.
        [parameters setValue:[NSNumber numberWithDouble:_srcCoord.longitude] forKey:kKeyLongitude1];
        [parameters setValue:[NSNumber numberWithDouble:_srcCoord.latitude] forKey:kKeyLatitude1];
    }
    
    // Destination post
    TradePost* post2 = [[TradePostMgr getInstance] getTradePostWithId:_projectedNextPost];
    if (post2.isNPCPost)
    {
        CLLocationCoordinate2D location = post2.coord;
        [parameters setValue:[NSNumber numberWithDouble:location.longitude] forKey:kKeyLongitude2];
        [parameters setValue:[NSNumber numberWithDouble:location.latitude] forKey:kKeyLatitude2];
    }
    else
    {
        [parameters setObject:_projectedNextPost forKey:kKeyPost2];
    }
    
    return parameters;
}

- (void) createFlyerPathOnServer
{
    // post parameters
    NSString *flyerPathUrl = [NSString stringWithFormat:@"users/%d/user_flyers/%@/flyer_paths", [[Player getInstance] id],
                               _userFlyerId];
    NSDictionary* parameters = [self createParametersForFlyerPath];
    
    // make a post request
    AFHTTPClient* httpClient = [[AFClientManager sharedInstance] traderPog];
    [httpClient postPath:flyerPathUrl
              parameters:parameters
                 success:^(AFHTTPRequestOperation *operation, id responseObject){
                     NSLog(@"FlyerPath created");
                     _flyerPathId = [responseObject valueForKeyPath:kKeyFlyerPathId];
                     NSString* utcdate = [responseObject valueForKeyPath:kKeyDepartureDate];
                     [self storeDepartureDate:utcdate];
                     _nextPostId = _projectedNextPost;
                     [self createRenderingForFlyer];
                     _creatingNextFlyerPath = FALSE;
                     //[self.delegate didCompleteHttpCallback:kFlyer_CreateNewFlyerPath, TRUE];
                 }
                 failure:^(AFHTTPRequestOperation* operation, NSError* error){
                     UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Server Failure"
                                                                       message:@"Unable to create flyer path. Please try again later."
                                                                      delegate:nil
                                                             cancelButtonTitle:@"OK"
                                                             otherButtonTitles:nil];
                     
                     [message show];
                     _creatingNextFlyerPath = FALSE;
                     //[self.delegate didCompleteHttpCallback:kFlyer_CreateNewFlyerPath, FALSE];
                 }
     ];
}

- (void) updateFlyerPath:(NSDictionary*)parameters
{    
    // make a post request
    AFHTTPClient* httpClient = [[AFClientManager sharedInstance] traderPog];
    NSString *flyerPathUrl = [NSString stringWithFormat:@"users/%d/user_flyers/%@/flyer_paths/%@",
                              [[Player getInstance] id], _userFlyerId, _flyerPathId];
    [httpClient putPath:flyerPathUrl
             parameters:parameters
                success:^(AFHTTPRequestOperation *operation, id responseObject){
                    NSLog(@"Flyer path data updated");
                    [self.delegate didCompleteHttpCallback:kPlayer_SavePlayerData, TRUE];
                }
                failure:^(AFHTTPRequestOperation* operation, NSError* error){
                    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Server Failure"
                                                                      message:@"Unable to update flyer path. Please try again later."
                                                                     delegate:nil
                                                            cancelButtonTitle:@"OK"
                                                            otherButtonTitles:nil];
                    
                    [message show];
                    [self.delegate didCompleteHttpCallback:kPlayer_SavePlayerData, FALSE];
                }
     ];
}

// Create rendering for flyer
- (void) createRenderingForFlyer
{    
    // create renderer
    self.srcCoord = [[[TradePostMgr getInstance] getTradePostWithId:[self curPostId]] coord];
    self.destCoord = [[[TradePostMgr getInstance] getTradePostWithId:[self nextPostId]] coord];
    self.flightPathRender = [[FlightPathOverlay alloc] initWithSrcCoord:[self srcCoord] destCoord:[self destCoord]];
    
    // flyer zero-angle is up; so, need to offset it by 90 degrees
    float angle = [MKMapView angleBetweenCoordinateA:[self srcCoord] coordinateB:[self destCoord]];
    angle += M_PI_2;
    _transform = CGAffineTransformMakeRotation(angle);
    if([self annotation])
    {
        [self.annotation setTransform:_transform];
    }
    
    // add rendering
    [[[[GameManager getInstance] gameViewController] mapControl] showFlightPathForFlyer:self];
}

#pragma mark - flight public
- (BOOL) departForPostId:(NSString *)postId
{
    if((![postId isEqualToString:[self curPostId]]) &&
       (![self nextPostId]))
    {        
        // Store the next post in a temp variable first
        _projectedNextPost = postId;
        _creatingNextFlyerPath = TRUE;
        [self createFlyerPathOnServer];
        return TRUE;
    }
    return FALSE;
}

- (void) updateAtDate:(NSDate *)currentTime
{
    if(!_creatingNextFlyerPath && [self nextPostId])
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
        _metersToDest = routeDist - (elapsed * [self getFlyerSpeed]);
        if(_metersToDest <= 0.0)
        {
            _metersToDest = 0.0;
            
            // arrived
            self.curPostId = [self nextPostId];
            self.nextPostId = nil;
            [[[[GameManager getInstance] gameViewController] mapControl] dismissFlightPathForFlyer:self];
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
    CLLocationCoordinate2D coordNow = [self srcCoord];
    if([self departureDate] != nil)
    {
        CLLocationDistance distMeters = metersDistance([self srcCoord], [self destCoord]);
        MKMapPoint srcPoint = MKMapPointForCoordinate([self srcCoord]);
        MKMapPoint destPoint = MKMapPointForCoordinate([self destCoord]);
        MKMapPoint routeVec = MKMapPointMake(destPoint.x - srcPoint.x, destPoint.y - srcPoint.y);
        double distPoints = sqrt((routeVec.x * routeVec.x) + (routeVec.y * routeVec.y));
        MKMapPoint routeVecNormalized = MKMapPointMake(routeVec.x / distPoints, routeVec.y / distPoints);
        
        CLLocationDistance distTraveledMeters = [self getFlyerSpeed] * elapsed;
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
