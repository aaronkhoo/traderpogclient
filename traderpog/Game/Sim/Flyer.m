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
#import "FlyerAnnotationView.h"
#import "GameManager.h"
#import "TradePost.h"
#import "TradePostMgr.h"
#import "Player.h"
#import "PogUIUtility.h"
#import "MKMapView+Pog.h"
#import "TradeManager.h"

static const float kFlyerDefaultSpeedMetersPerSec = 100.0f;
static const NSInteger kStormCountOne = 10;
static const NSInteger kStormCountTwo = 5;
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
static NSString* const kKeyItemId = @"itemId";
static NSString* const kKeyNumItems = @"numItems";
static NSString* const kKeyCostBasis = @"costBasis";
static NSString* const kKeyOrderItemId = @"orderItemId";
static NSString* const kKeyOrderNumItems = @"orderNumItems";
static NSString* const kKeyOrderMoney = @"orderPrice";

@interface Flyer ()
{
    // temp variable for storing next flight path before it is confirmed by server
    BOOL _updatingFlyerPathOnServer;
    NSString* _projectedNextPost;
    BOOL _doneWithCurrentPath;
    
    // flight enroute processing
    NSDate* _departureDate;
    CLLocationCoordinate2D _srcCoord;
    CLLocationCoordinate2D _destCoord;
    CLLocationDistance _metersToDest;
}
@property (nonatomic,strong) NSDate* departureDate;
@property (nonatomic) CLLocationCoordinate2D srcCoord;
@property (nonatomic) CLLocationCoordinate2D destCoord;

- (CLLocationCoordinate2D) flyerCoordinateAtTimeSinceDeparture:(NSTimeInterval)elapsed;
- (CLLocationCoordinate2D) flyerCoordinateAtTimeAhead:(NSTimeInterval)timeAhead;
- (NSDictionary*) createParametersForFlyerPath;
@end

@implementation Flyer
@synthesize curPostId = _curPostId;
@synthesize nextPostId = _nextPostId;
@synthesize itemId = _itemId;
@synthesize numItems = _numItems;
@synthesize costBasis = _costBasis;
@synthesize orderItemId = _orderItemId;
@synthesize orderNumItems = _orderNumItems;
@synthesize orderPrice = _orderPrice;
@synthesize flightPathRender = _flightPathRender;
@synthesize coord = _coord;
@synthesize departureDate = _departureDate;
@synthesize srcCoord = _srcCoord;
@synthesize destCoord = _destCoord;
@synthesize transform = _transform;
@synthesize delegate = _delegate;
@synthesize initializeFlyerOnMap = _initializeFlyerOnMap;

- (id) initWithPostAndFlyer:(TradePost*)tradePost, NSInteger flyerTypeIndex
{
    self = [super init];
    if(self)
    {
        _updatingFlyerPathOnServer = FALSE;
        _projectedNextPost = nil;
        _doneWithCurrentPath = FALSE;
        _initializeFlyerOnMap = FALSE;
        
        _flyerTypeIndex = flyerTypeIndex;
        _coord = [tradePost coord];
        _flyerPathId = nil;
        
        _curPostId = [tradePost postId];
        _nextPostId = nil;
        _itemId = nil;
        _numItems = 0;
        _costBasis = 0.0f;
        _orderItemId = nil;
        _orderNumItems = 0;
        _orderPrice = 0;
        _flightPathRender = nil;
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
        _updatingFlyerPathOnServer = FALSE;
        _projectedNextPost = nil;
        _initializeFlyerOnMap = FALSE;
        
        _userFlyerId = [NSString stringWithFormat:@"%d", [[dict valueForKeyPath:kKeyUserFlyerId] integerValue]];
        
        NSString* flyerTypeId = [NSString stringWithFormat:@"%d", [[dict valueForKeyPath:kKeyFlyerId] integerValue]];
        _flyerTypeIndex = [[FlyerTypes getInstance] getFlyerIndexById:flyerTypeId];
        
        NSArray* paths_array = [dict valueForKeyPath:@"flyer_paths"];
        NSDictionary* path_dict = [paths_array objectAtIndex:0];
        
        _flyerPathId = [NSString stringWithFormat:@"%d", [[path_dict valueForKeyPath:kKeyFlyerPathId] integerValue]];
                                                          
        id obj = [path_dict valueForKeyPath:kKeyDone];
        if ((NSNull *)obj == [NSNull null])
        {
            _doneWithCurrentPath = FALSE;
        }
        else
        {
            _doneWithCurrentPath = [obj boolValue];
        }

        obj = [path_dict valueForKeyPath:kKeyPost1];
        if ((NSNull *)obj == [NSNull null])
        {
            // No post ID, so it must be stored in the longitude/latitude values
            _srcCoord.latitude = [[path_dict valueForKeyPath:kKeyLatitude1] doubleValue];
            _srcCoord.longitude = [[path_dict valueForKeyPath:kKeyLongitude1] doubleValue];
        }
        else
        {
            _curPostId = [NSString stringWithFormat:@"%d", [obj integerValue]];
            _srcCoord = [[[TradePostMgr getInstance] getTradePostWithId:_curPostId] coord];
        }
        
        obj = [path_dict valueForKeyPath:kKeyPost2];
        if ((NSNull *)obj == [NSNull null])
        {
            // No post ID, so it must be stored in the longitude/latitude values
            _destCoord.latitude = [[path_dict valueForKeyPath:kKeyLatitude2] doubleValue];
            _destCoord.longitude = [[path_dict valueForKeyPath:kKeyLongitude2] doubleValue];
        }
        else
        {
            _nextPostId = [NSString stringWithFormat:@"%d", [obj integerValue]];
            _destCoord = [[[TradePostMgr getInstance] getTradePostWithId:_nextPostId] coord];
        }
        
        // Flyer was done flying on this path. Move next to source. Clear up next and dest.
        if (_doneWithCurrentPath)
        {
            _curPostId = _nextPostId;
            _srcCoord = _destCoord;
            
            _nextPostId = nil;
            _departureDate = nil;
        }
        
        NSString* utcdate = [path_dict valueForKeyPath:kKeyDepartureDate];
        [self storeDepartureDate:utcdate];
        
        // inventory
        obj = [path_dict valueForKeyPath:kKeyItemId];
        if ((NSNull *)obj == [NSNull null])
        {
            // no item for this flyer
            _itemId = nil;
        }
        else
        {
            _itemId = [NSString stringWithFormat:@"%d", [obj integerValue]];
        }
        obj = [path_dict valueForKeyPath:kKeyNumItems];
        if ((NSNull *)obj == [NSNull null])
        {
            _numItems = 0;
        }
        else
        {
            _numItems = [obj unsignedIntegerValue];
        }
        obj = [path_dict valueForKeyPath:kKeyCostBasis];
        if ((NSNull *)obj == [NSNull null])
        {
            _costBasis = 0.0f;
        }
        else
        {
            _costBasis = [obj floatValue];
        }
        
        // escrow
        obj = [path_dict valueForKeyPath:kKeyOrderItemId];
        if ((NSNull *)obj == [NSNull null])
        {
            // no item for this flyer
            _orderItemId = nil;
        }
        else
        {
            _orderItemId = [NSString stringWithFormat:@"%d", [obj integerValue]];
        }
        obj = [path_dict valueForKeyPath:kKeyOrderNumItems];
        if ((NSNull *)obj == [NSNull null])
        {
            _orderNumItems = 0;
        }
        else
        {
            _orderNumItems = [obj unsignedIntValue];
        }
        obj = [path_dict valueForKeyPath:kKeyOrderMoney];
        if ((NSNull *)obj == [NSNull null])
        {
            _orderPrice = 0;
        }
        else
        {
            _orderPrice = [obj unsignedIntValue];
        }
        
        // init runtime transient vars
        _coord = _srcCoord;
        _flightPathRender = nil;
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
                     _userFlyerId = [NSString stringWithFormat:@"%d", [[responseObject valueForKeyPath:kKeyUserFlyerId] integerValue]];
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

- (NSInteger) getStormsCount
{
    // Get a number between 1 and 100
    NSInteger rndNumber = (arc4random() % 100) + 1;
    
    if (rndNumber <= kStormCountTwo)
    {
        return 1;
    }
    else if (rndNumber <= (kStormCountOne + kStormCountTwo))
    {
        return 2;
    }
    else
    {
        return 0;
    }
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
    
    // Set a storm count
    NSInteger stormCount = [self getStormsCount];
    [parameters setObject:[NSNumber numberWithInteger:stormCount] forKey:kKeyStorms];
    [parameters setObject:[NSNumber numberWithInteger:0] forKey:kKeyStormed];
    
    [parameters setObject:[NSNumber numberWithBool:NO] forKey:kKeyDone];
    
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
                     _flyerPathId = [NSString stringWithFormat:@"%d", [[responseObject valueForKeyPath:kKeyFlyerPathId] integerValue]];
                     NSString* utcdate = [responseObject valueForKeyPath:kKeyDepartureDate];
                     [self storeDepartureDate:utcdate];
                     _nextPostId = _projectedNextPost;
                     [self createRenderingForFlyer];
                     _updatingFlyerPathOnServer = FALSE;
                 }
                 failure:^(AFHTTPRequestOperation* operation, NSError* error){
                     UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Server Failure"
                                                                       message:@"Unable to create flyer path. Please try again later."
                                                                      delegate:nil
                                                             cancelButtonTitle:@"OK"
                                                             otherButtonTitles:nil];
                     
                     [message show];
                     _updatingFlyerPathOnServer = FALSE;
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
                    _updatingFlyerPathOnServer = FALSE;
                }
                failure:^(AFHTTPRequestOperation* operation, NSError* error){
                    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Server Failure"
                                                                      message:@"Unable to update flyer path. Please try again later."
                                                                     delegate:nil
                                                            cancelButtonTitle:@"OK"
                                                            otherButtonTitles:nil];
                    
                    [message show];
                    _updatingFlyerPathOnServer = FALSE;
                }
     ];
}

// Create rendering for flyer
- (void) createRenderingForFlyer
{    
    // create renderer
    if ([self curPostId])
    {
        // If a current post is specified, then use that post's coordinates.
        // Otherwise, the srcCoords are already specified. This happens when the source post is
        // an NPC post that isn't stored on the server.
        self.srcCoord = [[[TradePostMgr getInstance] getTradePostWithId:[self curPostId]] coord];   
    }
    if ([self nextPostId])
    {
        // Same as above. 
        self.destCoord = [[[TradePostMgr getInstance] getTradePostWithId:[self nextPostId]] coord];   
    }
    self.flightPathRender = [[FlightPathOverlay alloc] initWithSrcCoord:[self srcCoord] destCoord:[self destCoord]];
    
    // flyer zero-angle is up; so, need to offset it by 90 degrees
    float angle = [MKMapView angleBetweenCoordinateA:[self srcCoord] coordinateB:[self destCoord]];
    angle += M_PI_2;
    self.transform = CGAffineTransformMakeRotation(angle);
    
    // add rendering
    [[[[GameManager getInstance] gameViewController] mapControl] showFlightPathForFlyer:self];
}

#pragma mark - inventory
- (void) addItemId:(NSString *)newItemId num:(unsigned int)num price:(unsigned int)price
{
    if([self itemId] &&
       (NSOrderedSame != [self.itemId compare:newItemId]))
    {
        // if different item, dump existing inventory
        self.numItems = 0;
        self.costBasis = 0.0f;
        NSLog(@"Flyer: dumped current items");
    }
    
    unsigned int newNumItems = [self numItems] + num;
    float newCostBasis = (((float) [self numItems] * [self costBasis]) + ((float)price * (float)num)) / ((float)newNumItems);

    self.costBasis = newCostBasis;
    self.itemId = newItemId;
    self.numItems = newNumItems;
    
    NSLog(@"Flyer: inventory updated %d items of %@ at cost %f", newNumItems, newItemId, newCostBasis);
    NSLog(@"Flyer: current (%d, %d, %@, %f)", [[Player getInstance] bucks], [self numItems], [self itemId], [self costBasis]);
}

// place an order in ecrow (will commit when flyer arrives at post and finishes loading)
- (void) orderItemId:(NSString *)itemId num:(unsigned int)num price:(unsigned int)price
{
    self.orderItemId = itemId;
    self.orderNumItems = num;
    self.orderPrice = price;
}

- (void) commitOutstandingOrder
{
    if([self orderItemId])
    {
        [self addItemId:[self orderItemId] num:[self orderNumItems] price:[self orderPrice]];
    }
}

#pragma mark - flight public
- (BOOL) departForPostId:(NSString *)postId
{
    if((![postId isEqualToString:[self curPostId]]) &&
       (![self nextPostId]))
    {        
        // Store the next post in a temp variable first
        _updatingFlyerPathOnServer = TRUE;
        _doneWithCurrentPath = FALSE;
        _projectedNextPost = postId;
        [self createFlyerPathOnServer];
        return TRUE;
    }
    return FALSE;
}

- (void) completeFlyerPath
{
    // ask TradeManager to handle arrival
    TradePost* arrivalPost = [[TradePostMgr getInstance] getTradePostWithId:[self nextPostId]];
    [[TradeManager getInstance] flyer:self didArriveAtPost:arrivalPost];
    
    // Clearing up the various parameters properly as the Flyer has arrived at its destination
    _metersToDest = 0.0;
    self.curPostId = [self nextPostId];
    _srcCoord = _destCoord;
    self.nextPostId = nil;
    [[[[GameManager getInstance] gameViewController] mapControl] dismissFlightPathForFlyer:self];
    _updatingFlyerPathOnServer = TRUE;
    NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithBool:YES], kKeyDone,
                                nil];
    [self updateFlyerPath:parameters];
    _doneWithCurrentPath = TRUE;
    
    /*
    [self didArriveAtPost:[self destPostId]];
    
     NSString* timeString = [PogUIUtility stringFromTimeInterval:0.0];
     UILabel* timeLabel = (UILabel*)[_timeTillDestView.subviews objectAtIndex:0];
     [timeLabel setText:timeString];
     
     if(annotView)
     {
     [annotView hideEnrouteTimer];
     }
     */
}

- (void) updateAtDate:(NSDate *)currentTime
{
    if(_initializeFlyerOnMap && !_updatingFlyerPathOnServer && !_doneWithCurrentPath)
    {
        // enroute
        CLLocationCoordinate2D curCoord = [self flyerCoordinateNow];
        [self setCoordinate:curCoord];
        
        if([self flightPathRender])
        {
            [self.flightPathRender setCurCoord:curCoord];
        }
        
        NSTimeInterval elapsed = -[self.departureDate timeIntervalSinceNow];
        CLLocationDistance routeDist = metersDistance([self srcCoord], [self destCoord]);
        _metersToDest = routeDist - (elapsed * [self getFlyerSpeed]);
        if(_metersToDest <= 0.0)
        {
            [self completeFlyerPath];
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


#pragma mark - MKAnnotation delegate
- (CLLocationCoordinate2D) coordinate
{
    return [self coord];
}

- (void) setCoordinate:(CLLocationCoordinate2D)newCoordinate
{
    self.coord = newCoordinate;
    /*
     self.curLocation = [[[CLLocation alloc] initWithLatitude:newCoordinate.latitude longitude:newCoordinate.longitude] autorelease];
     if(_flyerAnnotView)
     {
     // mapView can decide to throw annotation-views into its reuse queue any time
     // so, if the view we have retained no longer belongs to us, clear it
     if(_flyerAnnotView && ([_flyerAnnotView annotation] != self))
     {
     NSLog(@"coordinate: flyer annotation recycled %@ (%@, %@)", _name, self, [_flyerAnnotView annotation]);
     [_flyerAnnotView release];
     _flyerAnnotView = nil;
     }
     else
     {
     [_flyerAnnotView setAnnotation:self];
     }
     }
     */
}

#pragma mark - MapAnnotationProtocol
- (MKAnnotationView*) annotationViewInMap:(MKMapView *)mapView
{
    MKAnnotationView* annotationView = (FlyerAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:kFlyerAnnotationViewReuseId];
    if(annotationView)
    {
        annotationView.annotation = self;
    }
    else
    {
        annotationView = [[FlyerAnnotationView alloc] initWithAnnotation:self];
    }
    return annotationView;
}


@end
