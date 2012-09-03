//
//  FlyerPath.m
//  traderpog
//
//  Created by Aaron Khoo on 9/2/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "AFClientManager.h"
#import "Flyer.h"
#import "FlyerPath.h"
#import "Player.h"
#import "PogUIUtility.h"
#import "TradePostMgr.h"

static const NSInteger kStormCountOne = 10;
static const NSInteger kStormCountTwo = 5;
static NSString* const kKeyFlyerPathId = @"id";
static NSString* const kKeyDepartureDate = @"created_at";
static NSString* const kKeyPost1 = @"post1";
static NSString* const kKeyPost2 = @"post2";
static NSString* const kKeyLongitude1 = @"longitude1";
static NSString* const kKeyLatitude1 = @"latitude1";
static NSString* const kKeyLongitude2 = @"longitude2";
static NSString* const kKeyLatitude2 = @"latitude2";
static NSString* const kKeyStorms= @"storms";
static NSString* const kKeyStormed= @"stormed";
static NSString* const kKeyDone = @"done";

@implementation FlyerPath
@synthesize curPostId = _curPostId;
@synthesize nextPostId = _nextPostId;
@synthesize departureDate = _departureDate;
@synthesize srcCoord = _srcCoord;
@synthesize destCoord = _destCoord;
@synthesize doneWithCurrentPath = _doneWithCurrentPath;
@synthesize updatingFlyerPathOnServer = _updatingFlyerPathOnServer;
@synthesize metersToDest = _metersToDest;

- (id) initWithPost:(TradePost*)tradePost
{
    self = [super init];
    if(self)
    {
        _updatingFlyerPathOnServer = FALSE;
        _projectedNextPost = nil;
        _doneWithCurrentPath = TRUE;
        _metersToDest = 0.0;
        
        _flyerPathId = nil;
        
        _curPostId = [tradePost postId];
        _nextPostId = nil;
        
        _departureDate = nil;
        _srcCoord = [tradePost coord];
        _destCoord = [tradePost coord];
    }
    return self;
}

- (id) initWithDictionary:(NSDictionary*)path_dict
{
    self = [super init];
    if(self)
    {
        // Clear variables
        _updatingFlyerPathOnServer = FALSE;
        _projectedNextPost = nil;
        
        _flyerPathId = [NSString stringWithFormat:@"%d", [[path_dict valueForKeyPath:kKeyFlyerPathId] integerValue]];
        
        id obj = [path_dict valueForKeyPath:kKeyDone];
        if ((NSNull *)obj == [NSNull null])
        {
            _doneWithCurrentPath = TRUE;
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
        
        // Departure date
        _departureDate = nil;
        obj = [path_dict valueForKeyPath:kKeyDepartureDate];
        if ((NSNull *)obj != [NSNull null])
        {
            NSString* utcdate = [NSString stringWithFormat:@"%@", obj];
            if (![utcdate isEqualToString:@"<null>"])
            {
                _departureDate = [PogUIUtility convertUtcToNSDate:utcdate];
            }
        }
        if (!_departureDate)
        {
            // For some reason, departure date from server is messed up
            // Set it to current time to prevent problems. 
            _departureDate = [[NSDate alloc] init];
        }
        
        _metersToDest = 0.0;
    }
    return self;
}

- (void) initFlyerPathOnMap
{
    if (_doneWithCurrentPath)
    {
        if(_nextPostId)
        {
            _destCoord = [[[TradePostMgr getInstance] getTradePostWithId:_nextPostId] coord];
        }
        else
        {
            // otherwise, destCoord would have loaded from server; so, do nothing
        }
        _curPostId = _nextPostId;
        _srcCoord = _destCoord;
        _nextPostId = nil;
        _departureDate = nil;
    }
    else
    {
        // retrieve end-point coordinates in case initWithDictionary was called prior to
        // TradePostMgr getting initialized from server
        if(_curPostId)
        {
            _srcCoord = [[[TradePostMgr getInstance] getTradePostWithId:_curPostId] coord];
        }
        else
        {
            // otherwise, _srcCoord would have loaded from server (npc post); so, do nothing here
        }
        if(_nextPostId)
        {
            _destCoord = [[[TradePostMgr getInstance] getTradePostWithId:_nextPostId] coord];
        }
        else
        {
            // otherwise, _destCoord would have loaded from server (npc post); so, do nothing here
        }
    }
}

- (BOOL) isEnrouteWhenLoaded
{
    return !_doneWithCurrentPath;
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

- (BOOL) departForPostId:(NSString *)postId userFlyerId:(NSString*)userFlyerId
{
    if((![postId isEqualToString:[self curPostId]]) &&
       (![self nextPostId]))
    {
        // Store the next post in a temp variable first
        _updatingFlyerPathOnServer = TRUE;
        _doneWithCurrentPath = FALSE;
        _projectedNextPost = postId;
        [self createFlyerPathOnServer:userFlyerId];
        return TRUE;
    }
    return FALSE;
}

- (NSDictionary*) createParametersForFlyerPath
{
    NSMutableDictionary* parameters = [NSMutableDictionary dictionaryWithCapacity:6];
    
    // Source post
    if (_curPostId)
    {
        TradePost* post1 = [[TradePostMgr getInstance] getTradePostWithId:_curPostId];
        if ([post1 isMemberOfClass:[NPCTradePost class]])
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
    if ([post2 isMemberOfClass:[NPCTradePost class]])
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

- (void) createFlyerPathOnServer:(NSString*)userFlyerId
{
    _departureDate = [[NSDate alloc] init];
    
    // post parameters
    NSString *flyerPathUrl = [NSString stringWithFormat:@"users/%d/user_flyers/%@/flyer_paths", [[Player getInstance] playerId], userFlyerId];
    NSDictionary* parameters = [self createParametersForFlyerPath];
    
    // make a post request
    AFHTTPClient* httpClient = [[AFClientManager sharedInstance] traderPog];
    [httpClient postPath:flyerPathUrl
              parameters:parameters
                 success:^(AFHTTPRequestOperation *operation, id responseObject){
                     NSLog(@"FlyerPath created");
                     _flyerPathId = [NSString stringWithFormat:@"%d", [[responseObject valueForKeyPath:kKeyFlyerPathId] integerValue]];
                     
                     // Departure date
                     NSString* utcdate = [NSString stringWithFormat:@"%@", [responseObject valueForKeyPath:kKeyDepartureDate]];
                     if (![utcdate isEqualToString:@"<null>"])
                     {
                         _departureDate = [PogUIUtility convertUtcToNSDate:utcdate];
                     }
                     
                     _nextPostId = _projectedNextPost;
                     
                     _updatingFlyerPathOnServer = FALSE;
                 }
                 failure:^(AFHTTPRequestOperation* operation, NSError* error){
                     UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Server Failure"
                                                                       message:@"Unable to create flyer path. Please try again later."
                                                                      delegate:nil
                                                             cancelButtonTitle:@"OK"
                                                             otherButtonTitles:nil];
                     
                     [message show];
                     
                     //[[TradeManager getInstance] flyer:self revertOrderFromPostId:_projectedNextPost];
                     _updatingFlyerPathOnServer = FALSE;
                 }
     ];
}

- (void) updateFlyerPath:(NSString*)userFlyerId parameters:(NSDictionary*)parameters
{
    // make a post request
    AFHTTPClient* httpClient = [[AFClientManager sharedInstance] traderPog];
    NSString *flyerPathUrl = [NSString stringWithFormat:@"users/%d/user_flyers/%@/flyer_paths/%@",
                              [[Player getInstance] playerId], userFlyerId, _flyerPathId];
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

- (void) completeFlyerPath:(NSString*)userFlyerId
{
    // Clearing up the various parameters properly as the Flyer has arrived at its destination
    _metersToDest = 0.0;
    _curPostId = _nextPostId;
    _srcCoord = _destCoord;
    self.nextPostId = nil;
    _updatingFlyerPathOnServer = TRUE;
    NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithBool:YES], kKeyDone,
                                nil];
    [self updateFlyerPath:userFlyerId parameters:parameters];
    _doneWithCurrentPath = TRUE;
}

- (BOOL) isEnroute
{
    BOOL result = NO;
    if(!_doneWithCurrentPath && [self curPostId] && [self nextPostId])
    {
        result = YES;
    }
    else if(_updatingFlyerPathOnServer && _projectedNextPost)
    {
        result = YES;
    }
    
    return result;
}

@end
