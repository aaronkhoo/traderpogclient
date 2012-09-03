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
#import "NPCTradePost.h"
#import "TradePostMgr.h"
#import "Player.h"
#import "MKMapView+Pog.h"
#import "TradeManager.h"
#import "GameNotes.h"

static const float kFlyerDefaultSpeedMetersPerSec = 10000.0f;
static NSString* const kKeyUserFlyerId = @"id";
static NSString* const kKeyFlyerId = @"flyer_info_id";

@interface Flyer ()
- (CLLocationCoordinate2D) flyerCoordinateAtTimeSinceDeparture:(NSTimeInterval)elapsed;
- (CLLocationCoordinate2D) flyerCoordinateAtTimeAhead:(NSTimeInterval)timeAhead;
@end

@implementation Flyer
@synthesize userFlyerId = _userFlyerId;
@synthesize flightPathRender = _flightPathRender;
@synthesize coord = _coord;
@synthesize isNewFlyer = _isNewFlyer;
@synthesize isAtOwnPost = _isAtOwnPost;
@synthesize transform = _transform;
@synthesize delegate = _delegate;
@synthesize initializeFlyerOnMap = _initializeFlyerOnMap;
@synthesize inventory = _inventory;
@synthesize path = _path;

- (id) initWithPostAndFlyer:(TradePost*)tradePost, NSInteger flyerTypeIndex
{
    self = [super init];
    if(self)
    {
        _initializeFlyerOnMap = FALSE;
        
        _flyerTypeIndex = flyerTypeIndex;

        // init transient variables
        _coord = [tradePost coord];
        _flightPathRender = nil;
        _transform = CGAffineTransformIdentity;

        // this flyer is newly created (see Flyer.h for more details)
        _isNewFlyer = YES;
        _isAtOwnPost = YES;
        
        _inventory = [[FlyerInventory alloc] init];
        _path = [[FlyerPath alloc] initWithPost:tradePost];
    }
    return self;
}

- (id) initWithDictionary:(NSDictionary*)dict
{
    self = [super init];
    if(self)
    {
        _initializeFlyerOnMap = FALSE;
        
        _userFlyerId = [NSString stringWithFormat:@"%d", [[dict valueForKeyPath:kKeyUserFlyerId] integerValue]];
        NSString* flyerTypeId = [NSString stringWithFormat:@"%d", [[dict valueForKeyPath:kKeyFlyerId] integerValue]];
        _flyerTypeIndex = [[FlyerTypes getInstance] getFlyerIndexById:flyerTypeId];
        
        NSArray* paths_array = [dict valueForKeyPath:@"flyer_paths"];
        NSDictionary* path_dict = [paths_array objectAtIndex:0];
        
        // Initialize inventory
        _inventory = [[FlyerInventory alloc] initWithDictionary:dict];
        
        // Initialize path
        _path = [[FlyerPath alloc] initWithDictionary:path_dict];
        
        // init runtime transient vars
        _coord = _path.srcCoord;
        _flightPathRender = nil;
        _transform = CGAffineTransformIdentity;
        
        // this flyer is loaded (see Flyer.h for more details)
        _isNewFlyer = NO;
        
        // this will get set in initFlyerOnMap when the game has info
        // to determine whether this flyer is at own post
        _isAtOwnPost = NO;
    }
    return self;
}

- (NSInteger) getFlyerSpeed
{
    FlyerType* current  = [[[FlyerTypes getInstance] flyerTypes] objectAtIndex:_flyerTypeIndex];
    return [current speed];
}

- (void) createNewUserFlyerOnServer
{
    // post parameters
    NSString *userFlyerPath = [NSString stringWithFormat:@"users/%d/user_flyers", [[Player getInstance] playerId]];
    FlyerType* current  = [[[FlyerTypes getInstance] flyerTypes] objectAtIndex:_flyerTypeIndex];
    NSString* flyerId = [current flyerId];
    NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                flyerId, kKeyFlyerId,
                                nil];
    
    // make a post request
    AFHTTPClient* httpClient = [[AFClientManager sharedInstance] traderPog];
    [httpClient setDefaultHeader:@"Init-Post-Id" value:[_path curPostId]];
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

- (void) createFlyerPathOnServer
{
    [_path createFlyerPathOnServer:_userFlyerId];
    [self createFlightPathRenderingForFlyer];
}

// Create flight-path rendering for flyer
- (void) createFlightPathRenderingForFlyer
{    
    // create renderer
    if ([_path curPostId])
    {
        // If a current post is specified, then use that post's coordinates.
        // Otherwise, the srcCoords are already specified. This happens when the source post is
        // an NPC post that isn't stored on the server.
        _path.srcCoord = [[[TradePostMgr getInstance] getTradePostWithId:[_path curPostId]] coord];
    }
    if ([_path nextPostId])
    {
        // Same as above. 
        _path.destCoord = [[[TradePostMgr getInstance] getTradePostWithId:[_path nextPostId]] coord];   
    }
    
    self.flightPathRender = [[FlightPathOverlay alloc] initWithSrcCoord:[_path srcCoord] destCoord:[_path destCoord]];
    
    // flyer zero-angle is up; so, need to offset it by 90 degrees
    float angle = [MKMapView angleBetweenCoordinateA:[_path srcCoord] coordinateB:[_path destCoord]];
    angle += M_PI_2;
    self.transform = CGAffineTransformMakeRotation(angle);
    
    // add rendering
    [[[[GameManager getInstance] gameViewController] mapControl] showFlightPathForFlyer:self];
}

#pragma mark - flight public

// called for restored flyers when game reboots
- (void) initFlyerOnMap
{
    [_path initFlyerPathOnMap];
    
    // init flight-state with all necessary info in place
    // Flyer initWithDictionary may get called prior to TradePostMgr receiving its server data;
    // so, this code here ensures dependent data (like coords that depend on postIds) are correctly setup
    if (_path.doneWithCurrentPath)
    {        
        [self setCoordinate:_path.srcCoord];
        
        // determine if I am at own post
        TradePost* curPost = [[TradePostMgr getInstance] getTradePostWithId:_path.curPostId];
        if([curPost isMemberOfClass:[MyTradePost class]])
        {
            self.isAtOwnPost = YES;
        }
    }
    else
    {
        CLLocationCoordinate2D curCoord = [self flyerCoordinateNow];
        [self setCoordinate:curCoord];
        [self createFlightPathRenderingForFlyer];
    }
    
    [[[GameManager getInstance] gameViewController].mapControl addAnnotationForFlyer:self];
    self.initializeFlyerOnMap = TRUE;
}

- (BOOL) departForPostId:(NSString *)postId
{
    BOOL success = [_path departForPostId:postId userFlyerId:_userFlyerId];
    if (success)
    {
        self.isAtOwnPost = NO;
    }
    [self createFlightPathRenderingForFlyer];
    
    return success;
}

- (void) completeFlyerPath
{
    // track distance
    CLLocationDistance routeDist = metersDistance([_path srcCoord], [_path destCoord]);
    [_inventory incrementTravelDistance:routeDist];
    
    // ask TradeManager to handle arrival
    TradePost* arrivalPost = [[TradePostMgr getInstance] getTradePostWithId:[_path nextPostId]];
    [[TradeManager getInstance] flyer:self didArriveAtPost:arrivalPost];
    if([arrivalPost isMemberOfClass:[MyTradePost class]])
    {
        self.isAtOwnPost = YES;
    }
    
    [_path completeFlyerPath:_userFlyerId];
    
    [[[[GameManager getInstance] gameViewController] mapControl] dismissFlightPathForFlyer:self];
    
    // broadcast arrival
    [[NSNotificationCenter defaultCenter] postNotificationName:kGameNoteFlyerDidArrive object:self];
}

- (void) updateAtDate:(NSDate *)currentTime
{
    if(_initializeFlyerOnMap && !_path.updatingFlyerPathOnServer && !_path.doneWithCurrentPath)
    {
        // enroute
        CLLocationCoordinate2D curCoord = [self flyerCoordinateNow];
        [self setCoordinate:curCoord];
        
        if([self flightPathRender])
        {
            [self.flightPathRender setCurCoord:curCoord];
        }
        
        NSTimeInterval elapsed = -[_path.departureDate timeIntervalSinceNow];
        CLLocationDistance routeDist = metersDistance([_path srcCoord], [_path destCoord]);
        _path.metersToDest = routeDist - (elapsed * [self getFlyerSpeed]);
        if(_path.metersToDest <= 0.0)
        {
            [_path completeFlyerPath:_userFlyerId];
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
    CLLocationCoordinate2D coordNow = [_path srcCoord];
    if([_path departureDate] != nil)
    {
        CLLocationDistance distMeters = metersDistance([_path srcCoord], [_path destCoord]);
        MKMapPoint srcPoint = MKMapPointForCoordinate([_path srcCoord]);
        MKMapPoint destPoint = MKMapPointForCoordinate([_path destCoord]);
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
            coordNow = [_path destCoord];
        }
    }
    return coordNow;    
}

- (CLLocationCoordinate2D) flyerCoordinateNow
{
    NSTimeInterval elapsed = -[_path.departureDate timeIntervalSinceNow];
    CLLocationCoordinate2D coordNow = [self flyerCoordinateAtTimeSinceDeparture:elapsed];
    return coordNow;
}

- (CLLocationCoordinate2D) flyerCoordinateAtTimeAhead:(NSTimeInterval)timeAhead
{
    NSTimeInterval elapsed = -[_path.departureDate timeIntervalSinceNow];
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
    
    if([self isAtOwnPost])
    {
        annotationView.enabled = NO;
    }
    else
    {
        annotationView.enabled = YES;
    }
    

    return annotationView;
}


@end
