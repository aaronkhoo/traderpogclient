//
//  FlyerPath.m
//  traderpog
//
//  Created by Aaron Khoo on 9/2/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "AFClientManager.h"
#import "AsyncHttpCallMgr.h"
#import "Flyer.h"
#import "FlyerPath.h"
#import "Player.h"
#import "PogUIUtility.h"
#import "TradePostMgr.h"

static const NSInteger kStormCountOne = 10;
static const NSInteger kStormCountTwo = 5;
static NSString* const kKeyVersion = @"version";
static NSString* const kKeyFlyerPathId = @"id";
static NSString* const kKeyDepartureDate = @"created_at";
static NSString* const kKeyPost1 = @"post1";
static NSString* const kKeyPost2 = @"post2";
static NSString* const kKeyLongitude1 = @"longitude1";
static NSString* const kKeyLatitude1 = @"latitude1";
static NSString* const kKeyLongitude2 = @"longitude2";
static NSString* const kKeyLatitude2 = @"latitude2";
static NSString* const kKeyMetersToDest= @"meterstodest";
static NSString* const kKeyStorms= @"storms";
static NSString* const kKeyStormed= @"stormed";
static NSString* const kKeyDone = @"done";

@interface FlyerPath ()
{
    // internal
    NSString* _createdVersion;
}
@end

@implementation FlyerPath
@synthesize curPostId = _curPostId;
@synthesize nextPostId = _nextPostId;
@synthesize departureDate = _departureDate;
@synthesize srcCoord = _srcCoord;
@synthesize destCoord = _destCoord;
@synthesize doneWithCurrentPath = _doneWithCurrentPath;

- (id) initWithPost:(TradePost*)tradePost
{
    self = [super init];
    if(self)
    {
        _doneWithCurrentPath = TRUE;
        
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
    }
    return self;
}

#pragma mark - NSCoding
- (void) encodeWithCoder:(NSCoder *)aCoder
{    
    [aCoder encodeObject:_createdVersion forKey:kKeyVersion];
    [aCoder encodeObject:_flyerPathId forKey:kKeyFlyerPathId];
    [aCoder encodeObject:_departureDate forKey:kKeyDepartureDate];
    
    // Only save the post if it is a "real" post and not an NPC one. NPC posts
    // don't get persisted between sessions.
    if (_curPostId)
    {
        TradePost* post1 = [[TradePostMgr getInstance] getTradePostWithId:_curPostId];
        if (!post1 || [post1 isMemberOfClass:[NPCTradePost class]])
        {
            [aCoder encodeObject:nil forKey:kKeyPost1];
        }
        else
        {
            [aCoder encodeObject:_curPostId forKey:kKeyPost1];
        }
    }
    else
    {
        [aCoder encodeObject:nil forKey:kKeyPost1];
    }
    
    // Only save the post if it is a "real" post and not an NPC one. NPC posts
    // don't get persisted between sessions.
    if (_nextPostId)
    {
        TradePost* post2 = [[TradePostMgr getInstance] getTradePostWithId:_nextPostId];
        if (!post2 || [post2 isMemberOfClass:[NPCTradePost class]])
        {
            [aCoder encodeObject:nil forKey:kKeyPost2];
        }
        else
        {
            [aCoder encodeObject:_nextPostId forKey:kKeyPost2];
        }
    }
    else
    {
        [aCoder encodeObject:nil forKey:kKeyPost2];
    }
    
    [aCoder encodeDouble:_srcCoord.latitude forKey:kKeyLatitude1];
    [aCoder encodeDouble:_srcCoord.longitude forKey:kKeyLongitude1];
    [aCoder encodeDouble:_destCoord.latitude forKey:kKeyLatitude2];
    [aCoder encodeDouble:_destCoord.longitude forKey:kKeyLongitude2];
    [aCoder encodeBool:_doneWithCurrentPath forKey:kKeyDone];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    _createdVersion = [aDecoder decodeObjectForKey:kKeyVersion];
    _flyerPathId = [aDecoder decodeObjectForKey:kKeyFlyerPathId];
    _departureDate = [aDecoder decodeObjectForKey:kKeyDepartureDate];
    _curPostId = [aDecoder decodeObjectForKey:kKeyPost1];
    _nextPostId = [aDecoder decodeObjectForKey:kKeyPost2];
    
    _srcCoord.latitude = [aDecoder decodeDoubleForKey:kKeyLatitude1];
    _srcCoord.longitude = [aDecoder decodeDoubleForKey:kKeyLongitude1];
    _destCoord.latitude = [aDecoder decodeDoubleForKey:kKeyLatitude2];
    _destCoord.longitude = [aDecoder decodeDoubleForKey:kKeyLongitude2];

    _doneWithCurrentPath = [aDecoder decodeBoolForKey:kKeyDone];
    return self;
}

#pragma mark - Public functions
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
        _departureDate = [[NSDate alloc] init];
        _doneWithCurrentPath = FALSE;
        _nextPostId = postId;
        
        NSString *flyerPathUrl = [NSString stringWithFormat:@"users/%d/user_flyers/%@/flyer_paths", [[Player getInstance] playerId], userFlyerId];
        NSDictionary* parameters = [self createParametersForFlyerPath];
        NSString* msg = [[NSString alloc] initWithFormat:@"Directing flyer to post %@ failed", _nextPostId];
        [[AsyncHttpCallMgr getInstance] newAsyncHttpCall:flyerPathUrl
                                          current_params:parameters
                                         current_headers:nil
                                             current_msg:msg
                                            current_type:postType];
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
    TradePost* post2 = [[TradePostMgr getInstance] getTradePostWithId:_nextPostId];
    if ([post2 isMemberOfClass:[NPCTradePost class]])
    {
        CLLocationCoordinate2D location = post2.coord;
        [parameters setValue:[NSNumber numberWithDouble:location.longitude] forKey:kKeyLongitude2];
        [parameters setValue:[NSNumber numberWithDouble:location.latitude] forKey:kKeyLatitude2];
    }
    else
    {
        [parameters setObject:_nextPostId forKey:kKeyPost2];
    }
    
    // Set a storm count
    NSInteger stormCount = [self getStormsCount];
    [parameters setObject:[NSNumber numberWithInteger:stormCount] forKey:kKeyStorms];
    [parameters setObject:[NSNumber numberWithInteger:0] forKey:kKeyStormed];
    
    [parameters setObject:[NSNumber numberWithBool:NO] forKey:kKeyDone];
    
    NSString* utcDate = [PogUIUtility convertNSDateToUtc:_departureDate];
    [parameters setObject:utcDate forKey:kKeyDepartureDate];
    
    return parameters;
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
                }
                failure:^(AFHTTPRequestOperation* operation, NSError* error){
                    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Server Failure"
                                                                      message:@"Unable to update flyer path. Please try again later."
                                                                     delegate:nil
                                                            cancelButtonTitle:@"OK"
                                                            otherButtonTitles:nil];
                    
                    [message show];
                }
     ];
}

- (void) completeFlyerPath:(NSString*)userFlyerId
{
    // Clearing up the various parameters properly as the Flyer has arrived at its destination
    _curPostId = _nextPostId;
    _srcCoord = _destCoord;
    self.nextPostId = nil;
    /*
     NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithBool:YES], kKeyDone,
                                nil];
    [self updateFlyerPath:userFlyerId parameters:parameters];
    */
     _doneWithCurrentPath = TRUE;
}

- (BOOL) isEnroute
{
    BOOL result = NO;
    if(!_doneWithCurrentPath && [self curPostId] && [self nextPostId])
    {
        result = YES;
    }
    
    return result;
}

@end
