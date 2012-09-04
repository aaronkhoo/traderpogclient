//
//  FlyerMgr.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/22/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "AFClientManager.h"
#import "FlyerMgr.h"
#import "Flyer.h"
#import "GameManager.h"
#import "Player.h"
#import "TradePost.h"
#import "TradePostMgr.h"
#import "WheelControl.h"
#import "WheelBubble.h"
#import "PogUIUtility.h"
#import "MapControl.h"
#import "TradeItemTypes.h"
#import "TradeItemType.h"
#import "WorldState.h"
#include "MathUtils.h"

static NSString* const kKeyVersion = @"version";
static NSString* const kKeyUserFlyerId = @"id";
static NSString* const kKeyDepartureDate = @"created_at";
static NSString* const kKeyFlyerArray = @"flyerArray";
static NSString* const kKeyLastUpdated= @"lastUpdated";
static NSString* const kFlyerMgrFilename = @"flyermgr.sav";
static double const refreshTime = -(60 * 15);
static NSUInteger kFlyerPreviewZoomLevel = 8;
static const CLLocationDistance kSimilarCoordThresholdMeters = 25.0;

@interface FlyerMgr ()
{
    // internal
    NSString* _createdVersion;
    
    // User flyer in the midst of being generated
    Flyer* _tempFlyer;
}
- (TradePost*) tradePosts:(NSArray*)tradePosts withinMeters:(CLLocationDistance)meters fromCoord:(CLLocationCoordinate2D)coord;
- (void) reconstructFlightPaths;
@end

@implementation FlyerMgr
@synthesize playerFlyers = _playerFlyers;
@synthesize delegate = _delegate;

- (id) init
{
    self = [super init];
    if(self)
    {
        _playerFlyers = [NSMutableArray arrayWithCapacity:10];
        _lastUpdate = nil;
        _previewMap = nil;
    }
    return self;
}

#pragma mark - NSCoding
- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_createdVersion forKey:kKeyVersion];
    [aCoder encodeObject:_playerFlyers forKey:kKeyFlyerArray];
    [aCoder encodeObject:_lastUpdate forKey:kKeyLastUpdated];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    _createdVersion = [aDecoder decodeObjectForKey:kKeyVersion];
    _playerFlyers = [aDecoder decodeObjectForKey:kKeyFlyerArray];
    _lastUpdate = [aDecoder decodeObjectForKey:kKeyLastUpdated];
    _previewMap = nil;
    
    return self;
}


#pragma mark - private functions

+ (NSString*) flyermgrFilePath
{
    NSString* docsDir = [GameManager documentsDirectory];
    NSString* filepath = [docsDir stringByAppendingPathComponent:kFlyerMgrFilename];
    return filepath;
}

#pragma mark - saved game data loading and unloading
+ (FlyerMgr*) loadFlyerMgrData
{
    FlyerMgr* current = nil;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* filepath = [FlyerMgr flyermgrFilePath];
    if ([fileManager fileExistsAtPath:filepath])
    {
        NSData* readData = [NSData dataWithContentsOfFile:filepath];
        if(readData)
        {
            current = [NSKeyedUnarchiver unarchiveObjectWithData:readData];
        }
    }
    return current;
}

- (void) saveFlyerMgrData
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
    NSError* error = nil;
    BOOL writeSuccess = [data writeToFile:[FlyerMgr flyermgrFilePath]
                                  options:NSDataWritingAtomic
                                    error:&error];
    if(writeSuccess)
    {
        NSLog(@"flyermgr file saved successfully");
    }
    else
    {
        NSLog(@"flyermgr file save failed: %@", error);
    }
}

- (void) removeFlyerMgrData
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* filepath = [FlyerMgr flyermgrFilePath];
    NSError *error = nil;
    if ([fileManager fileExistsAtPath:filepath])
    {
        [fileManager removeItemAtPath:filepath error:&error];
    }
}

#pragma mark - Public functions
- (BOOL) needsRefresh
{
    return (!_lastUpdate) || ([_lastUpdate timeIntervalSinceNow] < refreshTime);
}

- (BOOL) newPlayerFlyerAtTradePost:(TradePost*)tradePost firstFlyer:(NSInteger)flyerTypeIndex
{
    if (_tempFlyer == nil)
    {
        Flyer* newFlyer = [[Flyer alloc] initWithPostAndFlyer:tradePost, flyerTypeIndex];
        [newFlyer setDelegate:[FlyerMgr getInstance]];
        _tempFlyer = newFlyer;
        [_tempFlyer createNewUserFlyerOnServer];
        return TRUE;
    }    
    return FALSE;
}

- (void) setTempFlyerToActive
{
    if (_tempFlyer)
    {
        // The temp TradePost has been successfully uploaded to the server, so move it
        // to the active list.
        [_playerFlyers addObject:_tempFlyer];
        
        // if post previewMap creation, then add this new flyer to previewMap
        if(_previewMap)
        {
            [_previewMap addAnnotationForFlyer:_tempFlyer];
        }
        
        // Add this tradepost as an annotation to the mapcontrol instance if the map control has already
        // been created. If it hasn't, then log and skip this step. It's possible that the mapcontrol
        // doesn't exist yet during the startup flow. This will be taken care of properly, see GameManager
        // for more details.
        if ([[GameManager getInstance] gameViewController].mapControl)
        {
            [[[GameManager getInstance] gameViewController].mapControl addAnnotationForFlyer:_tempFlyer];
            _tempFlyer.initializeFlyerOnMap = TRUE;
        }
        else
        {
            NSLog(@"Map control has not been initialized!");
        }
        _tempFlyer = nil;
    }
}

- (Flyer*) getFlyerById:(NSString*)userFlyerId
{
    Flyer* flyerById = nil;
    for (Flyer* current in _playerFlyers)
    {
        if ([current.userFlyerId compare:userFlyerId] == NSOrderedSame)
        {
            flyerById = current;
        }
    }
    return flyerById;
}

- (BOOL) clearOldFlyerInfoIfNecessary:(NSDictionary*)dict
{
    BOOL cleared = TRUE;
    // Get the userFlyerId
    NSString* userFlyerId = [NSString stringWithFormat:@"%d", [[dict valueForKeyPath:kKeyUserFlyerId] integerValue]];
    Flyer* current = [self getFlyerById:userFlyerId];
    if (current)
    {
        NSArray* paths_array = [dict valueForKeyPath:@"flyer_paths"];
        NSDictionary* path_dict = [paths_array objectAtIndex:0];
        
        // get the departure date from the server
        NSDate* departureDate = nil;
        id obj = [path_dict valueForKeyPath:kKeyDepartureDate];
        if ((NSNull *)obj != [NSNull null])
        {
            NSString* utcdate = [NSString stringWithFormat:@"%@", obj];
            if (![utcdate isEqualToString:@"<null>"])
            {
                departureDate = [PogUIUtility convertUtcToNSDate:utcdate];
            }
        }
        
        if (departureDate)
        {
            if ([departureDate timeIntervalSinceDate:[[current path] departureDate]] < 0)
            {
                // Departure date from server is earlier than current. Keep it. 
                cleared = FALSE;
            }
        }
        else
        {
            // Something is wrong with the departure date from the server
            // Keep the local copy
            cleared = FALSE;
        }
        
        if (cleared)
        {
            // We should remove this object and recreate it using the one from the server
            [_playerFlyers removeObjectIdenticalTo:current];
        }
    }
    return cleared;
}

- (void) createFlyersArray:(id)responseObject
{
    for (NSDictionary* flyer in responseObject)
    {
        if ([self clearOldFlyerInfoIfNecessary:flyer])
        {
            // old flyer info was either not there or removed; recreate from server
            Flyer* current = [[Flyer alloc] initWithDictionary:flyer];
            [self.playerFlyers addObject:current];
        }
    }
}

- (void) retrieveUserFlyersFromServer
{
    // make a get request
    AFHTTPClient* httpClient = [[AFClientManager sharedInstance] traderPog];
    NSString *userFlyerPath = [NSString stringWithFormat:@"users/%d/user_flyers", [[Player getInstance] playerId]];
    [httpClient getPath:userFlyerPath
             parameters:nil
                success:^(AFHTTPRequestOperation *operation, id responseObject){
                    NSLog(@"Retrieved: %@", responseObject);
                    [self createFlyersArray:responseObject];
                    _lastUpdate = [NSDate date];
                    [self saveFlyerMgrData];
                    [self.delegate didCompleteHttpCallback:kFlyerMgr_ReceiveFlyers, TRUE];
                }
                failure:^(AFHTTPRequestOperation* operation, NSError* error){
                    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Server Failure"
                                                                      message:@"Unable to create retrieve flyers. Please try again later."
                                                                     delegate:nil
                                                            cancelButtonTitle:@"OK"
                                                            otherButtonTitles:nil];
                    
                    [message show];
                    [self.delegate didCompleteHttpCallback:kFlyerMgr_ReceiveFlyers, FALSE];
                }
     ];
}

- (void) updateFlyersAtDate:(NSDate *)currentTime
{
    for (Flyer* cur in _playerFlyers)
    {
        [cur updateAtDate:currentTime];
    }
}

// init existing flyers on the map (called when game reboots)
- (void) initFlyersOnMap
{
    [self reconstructFlightPaths];
    for (Flyer* currentFlyer in _playerFlyers)
    {
        // put them on the map
        [currentFlyer initFlyerOnMap];
    }
}

// determine whether a given coordinate is already in the given tradepost array
// coord is considered similar to a location in the array if they are less
// than a threshold meters apart (25 meters)
// returns the postId if coord matches; otherwise, returns nil
- (TradePost*) tradePosts:(NSArray*)tradePosts withinMeters:(CLLocationDistance)meters fromCoord:(CLLocationCoordinate2D)coord
{
    TradePost* result = nil;
    for(TradePost* cur in tradePosts)
    {
        MKMapPoint origin = MKMapPointForCoordinate(coord);
        MKMapPoint dest = MKMapPointForCoordinate([cur coordinate]);
        CLLocationDistance dist = MKMetersBetweenMapPoints(origin, dest);
        if(dist <= meters)
        {
            result = cur;
        }
    }
    return result;
}

- (void) reconstructFlightPaths
{
    // array of npc tradeposts
    NSMutableArray* patchPosts = [NSMutableArray arrayWithCapacity:10];
    
    // collect coordinates of all dangling end points
    for(Flyer* cur in _playerFlyers)
    {
        // only patch if this is a loaded flyer
        if(![cur isNewFlyer])
        {
            TradeItemType* itemType = nil;
            if([[cur inventory] orderItemId])
            {
                itemType = [[TradeItemTypes getInstance] getItemTypeForId:[[cur inventory] orderItemId]];
            }
            else
            {
                NSArray* itemTypes = [[TradeItemTypes getInstance] getItemTypesForTier:kTradeItemTierMin];
                unsigned int randItem = RandomWithinRange(0, [itemTypes count]-1);
                itemType = [itemTypes objectAtIndex:randItem];                
            }
            if(![[cur path] curPostId])
            {
                TradePost* post = [self tradePosts:patchPosts withinMeters:kSimilarCoordThresholdMeters fromCoord:[[cur path] srcCoord]];
                if(!post)
                {
                    // patch a new npc post here
                    unsigned int playerBucks = [[Player getInstance] bucks];
                    post = [[TradePostMgr getInstance] newNPCTradePostAtCoord:[[cur path] srcCoord] bucks:playerBucks];
                    [patchPosts addObject:post];
                }
                cur.path.curPostId = [post postId];
            }
            if(![[cur path] nextPostId])
            {
                TradePost* post = [self tradePosts:patchPosts withinMeters:kSimilarCoordThresholdMeters fromCoord:[[cur path] destCoord]];
                if(!post)
                {
                    // patch a new npc post here
                    post = [[TradePostMgr getInstance] newNPCTradePostAtCoord:[[cur path] destCoord] bucks:0];
                    [patchPosts addObject:post];
                }
                cur.path.nextPostId = [post postId];
            }
        }
    }
}

- (void) refreshFromWorldState:(WorldState *)worldState
{
    for(Flyer* cur in [self playerFlyers])
    {
        [worldState setDataIntoFlyer:cur];
    }
}

#pragma mark - queries

// returns an array of ids for tradeposts that has a Flyer
// returns nil if all Flyers are enroute
- (NSArray*) tradePostIdsWithFlyers
{
    NSMutableArray* result = [NSMutableArray arrayWithCapacity:[self.playerFlyers count]];
    for(Flyer* cur in [self playerFlyers])
    {
        if((![[cur path] isEnroute]) && ([[cur path] curPostId]))
        {
            [result addObject:[[cur path] curPostId]];
        }
    }
    if(![result count])
    {
        // if no flyers, return nil
        result = nil;
    }
    return result;
}

#pragma mark - HttpCallbackDelegate
- (void) didCompleteHttpCallback:(NSString*)callName, BOOL success
{
    if (success)
    {
        [self setTempFlyerToActive];
        [self saveFlyerMgrData];
    }
    [[GameManager getInstance] selectNextGameUI];
}

#pragma mark - WheelDataSource
- (unsigned int) numItemsInWheel:(WheelControl *)wheel
{
    unsigned int num = [_playerFlyers count];
    return num;
}


- (WheelBubble*) wheel:(WheelControl *)wheel bubbleAtIndex:(unsigned int)index
{
    WheelBubble* contentView = [wheel dequeueResuableBubble];
    UILabel* labelView = nil;
    if(nil == contentView)
    {
        CGRect contentRect = CGRectMake(5.0f, 5.0f, 30.0f, 30.0f);
        contentView = [[WheelBubble alloc] initWithFrame:contentRect];
    }
    labelView = [contentView labelView];
    labelView.backgroundColor = [UIColor clearColor];
    [labelView setText:[NSString stringWithFormat:@"%d", index]];
    contentView.backgroundColor = [UIColor redColor];
    
    [PogUIUtility setCircleForView:contentView];
    return contentView;
}

- (UIView*) wheel:(WheelControl*)wheel previewContentInitAtIndex:(unsigned int)index;
{
    MKMapView* result = nil;
    if([_playerFlyers count])
    {
        if(_previewMap)
        {
            result = [_previewMap view];
        }
        else
        {
            CGRect superFrame = wheel.previewView.bounds;
            result = [[MKMapView alloc] initWithFrame:superFrame];
            index = MIN(index, [_playerFlyers count]-1);
            Flyer* initFlyer = [_playerFlyers objectAtIndex:index];
            _previewMap = [[MapControl alloc] initWithMapView:result
                                                    andCenter:[initFlyer coord]
                                                  atZoomLevel:kFlyerPreviewZoomLevel];
            
            // add all existing flyers to previewMap
            for(Flyer* cur in _playerFlyers)
            {
                [_previewMap addAnnotationForFlyer:cur];
            }
        }
    }
    return result;
}

#pragma mark - WheelProtocol
- (void) wheelDidMoveTo:(unsigned int)index
{
    NSLog(@"wheel moved to %d",index);
    if([_playerFlyers count])
    {
        index = MIN(index, [_playerFlyers count]-1);
        Flyer* curFlyer = [_playerFlyers objectAtIndex:index];
        if([_previewMap trackedAnnotation] != curFlyer)
        {
            [_previewMap centerOn:[curFlyer coord] animated:YES];
            [_previewMap startTrackingAnnotation:curFlyer];
        }
    }
}

- (void) wheelDidSettleAt:(unsigned int)index
{
    // do nothing
}

- (void) wheel:(WheelControl*)wheel didPressOkOnIndex:(unsigned int)index
{
    if([_playerFlyers count])
    {
        index = MIN(index, [_playerFlyers count]-1);
        Flyer* curFlyer = [_playerFlyers objectAtIndex:index];
//        [wheel.superMap centerOn:[curFlyer coord] animated:YES];
//        [wheel.superMap startTrackingAnnotation:curFlyer];
//        [wheel.superMap centerOnFlyer:curFlyer animated:YES];
        [[GameManager getInstance] wheel:wheel commitOnFlyer:curFlyer];
    }
}

- (void) wheel:(WheelControl *)wheel didPressCloseOnIndex:(unsigned int)index
{
    // inform GameManager to pop back to idle
    [[GameManager getInstance] popGameStateToLoop];
}

- (void) wheel:(WheelControl*)wheel willShowAtIndex:(unsigned int)index
{
    if([_playerFlyers count])
    {
        index = MIN(index, [_playerFlyers count]-1);
        Flyer* curFlyer = [_playerFlyers objectAtIndex:index];
        if([_previewMap trackedAnnotation] != curFlyer)
        {
            [_previewMap centerOn:[curFlyer coord] animated:YES];
            [_previewMap startTrackingAnnotation:curFlyer];
        }
    }
}

- (void) wheel:(WheelControl*)wheel willHideAtIndex:(unsigned int)index
{
    [_previewMap stopTrackingAnnotation];
}

#pragma mark - Singleton
static FlyerMgr* singleton = nil;
+ (FlyerMgr*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
            // First, try to load the flyermgr data from disk
            singleton = [FlyerMgr loadFlyerMgrData];
            if (!singleton)
            {
                singleton = [[FlyerMgr alloc] init];
            }
		}
	}
	return singleton;
}

+ (void) destroyInstance
{
	@synchronized(self)
	{
		singleton = nil;
	}
}

@end
