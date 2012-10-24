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
#import "GameColors.h"
#import "ImageManager.h"
#include "MathUtils.h"
#import "MetricLogger.h"
#import "GameAnim.h"
#import "ScanManager.h"
#import "FlyerLabFactory.h"
#import "FlyerTypes.h"
#import "FlyerType.h"
#import "FlyerBuyConfirmScreen.h"
#import "MBProgressHUD.h"
#import <QuartzCore/QuartzCore.h>

static NSString* const kKeyVersion = @"version";
static NSString* const kKeyUserFlyerId = @"id";
static NSString* const kKeyDepartureDate = @"created_at";
static NSString* const kKeyFlyerArray = @"flyerArray";
static NSString* const kKeyLastUpdated= @"lastUpdated";
static NSString* const kFlyerMgrFilename = @"flyermgr.sav";
static double const refreshTime = -(60 * 15);
static NSUInteger kFlyerPreviewZoomLevel = 8;
static const CLLocationDistance kSimilarCoordThresholdMeters = 25.0;

static const float kBubbleBorderWidth = 1.5f;

@interface FlyerMgr ()
{
    // internal
    NSString* _createdVersion;
    
    // User flyer in the midst of being generated
    Flyer* _tempFlyer;
    
    // cached purchaseable flyer-type-indices
    NSArray* _cachedPurchaseables;
}
- (TradePost*) tradePosts:(NSArray*)tradePosts withinMeters:(CLLocationDistance)meters fromCoord:(CLLocationCoordinate2D)coord;
- (void) reconstructFlightPaths;
- (void) refreshPreviewForWheel:(WheelControl*)wheel atIndex:(unsigned int)index;
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
        _cachedPurchaseables = nil;
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
    _cachedPurchaseables = nil;
    
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
- (void) clearAllFlyers
{
    _playerFlyers = [NSMutableArray arrayWithCapacity:10];
}

- (void) resetRefresh
{
    _lastUpdate = nil;
}

- (BOOL) needsRefresh
{
    return (!_lastUpdate) || ([_lastUpdate timeIntervalSinceNow] < refreshTime);
}

- (BOOL) newPlayerFlyerAtTradePost:(TradePost*)tradePost firstFlyer:(NSInteger)flyerTypeIndex
{
    BOOL result = [self newPlayerFlyerAtTradePost:tradePost flyerTypeIndex:flyerTypeIndex isNewPurchase:NO];
    return result;
}

- (BOOL) newPlayerFlyerAtTradePost:(TradePost*)tradePost purchasedFlyerTypeIndex:(NSInteger)flyerTypeIndex
{
    BOOL result = [self newPlayerFlyerAtTradePost:tradePost flyerTypeIndex:flyerTypeIndex isNewPurchase:YES];
    return result;
}

- (BOOL) newPlayerFlyerAtTradePost:(TradePost*)tradePost flyerTypeIndex:(NSInteger)flyerTypeIndex isNewPurchase:(BOOL)isNewPurchase
{
    if (_tempFlyer == nil)
    {
        Flyer* newFlyer = [[Flyer alloc] initWithPost:tradePost flyerTypeIndex:flyerTypeIndex isNewPurchase:isNewPurchase];
        [newFlyer setDelegate:[FlyerMgr getInstance]];
        
        // lande new flyer at post that creates it
        tradePost.flyerAtPost = newFlyer;
        
        // create it on server
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
        
        if([_tempFlyer isNewlyPurchased])
        {
            // if newly purchased, need to init it on map
            [_tempFlyer initFlyerOnMap];
        }
        
        [MetricLogger logCreateObject:@"Flyer" slot:[_playerFlyers count] member:[[Player getInstance] isMember]];
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
            if ([departureDate timeIntervalSinceDate:[[current path] departureDate]] <= 0.0)
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
            else
            {
                // Else if there's a dangling post that couldn't be resolved. 
                TradePost* post = [[TradePostMgr getInstance] getTradePostWithId:[[cur path] curPostId]];
                if (!post)
                {
                    NSLog(@"Could not resolve current post! Replacing with NPC post.");
                    
                    // Create a random NPC post first
                    float curAngle = RandomFrac() * 2.0f * M_PI;
                    float randFrac = RandomFrac();
                    NPCTradePost* newPost = [[ScanManager getInstance] generateSinglePostAtCoordAndAngle:[[[TradePostMgr getInstance] getFirstMyTradePost] coord]
                                                                                                curAngle:curAngle
                                                                                                randFrac:randFrac];
                    [patchPosts addObject:newPost];
                    
                    // Set the current path to use it
                    cur.path.curPostId = [newPost postId];
                    cur.path.srcCoord = newPost.coord;
                }
            }                
                
            if(![[cur path] nextPostId] && ![[cur path] doneWithCurrentPath])
            {
                // only patch nextPost if not doneWithCurrentPath
                // otherwise, nextPostId is supposed to be nil
                TradePost* post = [self tradePosts:patchPosts withinMeters:kSimilarCoordThresholdMeters fromCoord:[[cur path] destCoord]];
                if(!post)
                {
                    // patch a new npc post here
                    post = [[TradePostMgr getInstance] newNPCTradePostAtCoord:[[cur path] destCoord] bucks:0];
                    [patchPosts addObject:post];
                }
                cur.path.nextPostId = [post postId];
            }
            else if(![[cur path] doneWithCurrentPath])
            {
                // Else if there's a dangling post that couldn't be resolved.
                TradePost* post = [[TradePostMgr getInstance] getTradePostWithId:[[cur path] nextPostId]];
                if (!post)
                {
                    NSLog(@"Could not resolve next post! Replacing with NPC post.");
                    
                    // Create a random NPC post first
                    float curAngle = RandomFrac() * 2.0f * M_PI;
                    float randFrac = RandomFrac();
                    NPCTradePost* newPost = [[ScanManager getInstance] generateSinglePostAtCoordAndAngle:[[[TradePostMgr getInstance] getFirstMyTradePost] coord]
                                                                                                curAngle:curAngle
                                                                                                randFrac:randFrac];
                    [patchPosts addObject:newPost];
                    
                    // Set the current path to use it
                    cur.path.nextPostId = [newPost postId];
                    cur.path.destCoord = newPost.coord;
                }
            }
            else if([[cur path] nextPostId])
            {
                // also check for dangling post if there is a nextPostId and we are done with path
                TradePost* post = [[TradePostMgr getInstance] getTradePostWithId:[[cur path] nextPostId]];
                if (!post)
                {
                    NSLog(@"Could not resolve next post! Replacing with NPC post.");
                    
                    // Create a random NPC post first
                    float curAngle = RandomFrac() * 2.0f * M_PI;
                    float randFrac = RandomFrac();
                    NPCTradePost* newPost = [[ScanManager getInstance] generateSinglePostAtCoordAndAngle:[[[TradePostMgr getInstance] getFirstMyTradePost] coord]
                                                                                                curAngle:curAngle
                                                                                                randFrac:randFrac];
                    [patchPosts addObject:newPost];
                    
                    // Set the current path to use it
                    cur.path.nextPostId = [newPost postId];
                    cur.path.destCoord = newPost.coord;
                }
            }
        }
    }
}

- (void) clearForQuitGame
{
    [self.previewMap removeAllAnnotations];
    self.previewMap = nil;
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

- (NSArray*) tradePostIdsInFlightpaths
{
    NSMutableSet* resultSet = [NSMutableSet setWithCapacity:[self.playerFlyers count]];
    for(Flyer* cur in [self playerFlyers])
    {
        if([cur.path isEnroute])
        {
            [resultSet addObject:[cur.path curPostId]];
            [resultSet addObject:[cur.path nextPostId]];
        }
    }
    return [resultSet allObjects];
}

- (Flyer*) flyerAtPostId:(NSString*)postId
{
    Flyer* result = nil;
    for(Flyer* cur in [self playerFlyers])
    {
        if((![[cur path] isEnroute]) && ([postId isEqualToString:[[cur path] curPostId]]))
        {
            result = cur;
            break;
        }
    }
    return result;
}

- (NSMutableArray*) unknownTradePostsFromFlyers
{
    NSMutableArray* result = [NSMutableArray arrayWithCapacity:[self.playerFlyers count]];
    for(Flyer* cur in [self playerFlyers])
    {        
        NSString* curPostId = [[cur path] curPostId];
        if (curPostId)
        {
            TradePost* post = [[TradePostMgr getInstance] getTradePostWithId:curPostId];
            if (!post)
            {
                [result addObject:curPostId];
            }
        }
        
        NSString* destPostId = [[cur path] nextPostId];
        if (destPostId)
        {
            TradePost* post = [[TradePostMgr getInstance] getTradePostWithId:destPostId];
            if (!post)
            {
                [result addObject:destPostId];
            }
        }
    }
    if(![result count])
    {
        result = nil;
    }
    return result;
}

- (void) refreshPreviewForWheel:(WheelControl*)wheel atIndex:(unsigned int)index
{
    if([_playerFlyers count] > index)
    {
        Flyer* curFlyer = [_playerFlyers objectAtIndex:index];
        if([_previewMap trackedAnnotation] != curFlyer)
        {
            [_previewMap centerOn:[curFlyer coord] animated:YES];
            //[_previewMap startTrackingAnnotation:curFlyer];
        }
        
        // label
        [wheel.previewLabel setNumberOfLines:1];
        [wheel.previewLabel setFont:[UIFont fontWithName:@"Marker Felt" size:19.0f]];
        if([curFlyer state] == kFlyerStateEnroute)
        {
            [wheel.previewLabel setText:@"Enroute"];
        }
        else
        {
            [wheel.previewLabel setText:@"Ready"];
        }
        
        // image
        [wheel.previewImageView setImage:nil];
        [wheel.previewImageView setHidden:YES];

        [_previewMap.view setHidden:NO];
    }
    else
    {
        // empty flyer slot
        [wheel.previewLabel setNumberOfLines:1];
        [wheel.previewLabel setText:@"Buy Flyer!"];
        [wheel.previewLabel setFont:[UIFont fontWithName:@"Marker Felt" size:19.0f]];
        
        NSArray* purchaseables = [self getPurchaseableFlyerTypeIndices];
        unsigned int lookupIndex = index - [_playerFlyers count];
        if(lookupIndex < [purchaseables count])
        {
            unsigned int flyerTypeIndex = [[purchaseables objectAtIndex:lookupIndex] unsignedIntValue];
            FlyerType* flyerType = [[FlyerTypes getInstance] getFlyerTypeAtIndex:flyerTypeIndex];
            NSString* flyerTypeName = [flyerType sideimg];
            NSString* imageName = [[FlyerLabFactory getInstance] sideImageForFlyerTypeNamed:flyerTypeName tier:1 colorIndex:0];
            UIImage* bgImage = [[ImageManager getInstance] getImage:imageName];
            [wheel.previewImageView setImage:bgImage];
            [wheel.previewImageView setHidden:NO];
        }
        [_previewMap.view setHidden:YES];
    }
}

- (Flyer*) homeOrHomeboundFlyer
{
    Flyer* result = nil;
    for(Flyer* cur in _playerFlyers)
    {
        TradePost* curPost = nil;
        if(kFlyerStateEnroute == [cur state])
        {
            // if enroute, check nextpost
            if([cur.path nextPostId])
            {
                curPost = [[TradePostMgr getInstance] getTradePostWithId:[cur.path nextPostId]];
            }
        }
        else if([cur.path curPostId])
        {
            // if not, check curpost
            curPost = [[TradePostMgr getInstance] getTradePostWithId:[cur.path curPostId]];
        }
        
        // if post is MyPost, then I am home or homebound
        if(curPost && [curPost isMemberOfClass:[MyTradePost class]])
        {
            result = cur;
            break;
        }
    }
    
    return result;
}


// the player is only allowed one flyer per type
// so, purchaseable flyers are the remaining flyer-types that the player doesn't have
- (NSArray*) getPurchaseableFlyerTypeIndices
{
    if(!_cachedPurchaseables)
    {
        NSMutableArray* result = [NSMutableArray arrayWithCapacity:6];
        for(unsigned int index = 0; index < [[FlyerTypes getInstance] numFlyerTypes]; ++index)
        {
            unsigned int numFlyers = [_playerFlyers count];
            for(Flyer* cur in _playerFlyers)
            {
                if(index == [cur flyerTypeIndex])
                {
                    break;
                }
                --numFlyers;
            }
            
            if(!numFlyers)
            {
                NSNumber* purchaseableIndexNum = [NSNumber numberWithUnsignedInt:index];
                [result addObject:purchaseableIndexNum];
            }
        }
        _cachedPurchaseables = result;
    }
    return _cachedPurchaseables;
}

#pragma mark - HttpCallbackDelegate
- (void) didCompleteHttpCallback:(NSString*)callName, BOOL success
{
    if (success)
    {
        GameViewController* game = [[GameManager getInstance] gameViewController];
        if(game)
        {
            [MBProgressHUD hideHUDForView:game.view animated:NO];
        }
        [self setTempFlyerToActive];
        [self saveFlyerMgrData];
    }
    [[GameManager getInstance] selectNextGameUI];
}

#pragma mark - WheelDataSource
- (unsigned int) numItemsInWheel:(WheelControl *)wheel
{
    unsigned int num = [[FlyerTypes getInstance] numFlyerTypes];
    return num;
}

- (WheelBubble*) wheel:(WheelControl *)wheel bubbleAtIndex:(unsigned int)index
{
    NSArray* purchaseables = [self getPurchaseableFlyerTypeIndices];
    WheelBubble* contentView = [wheel dequeueResuableBubble];
    if(nil == contentView)
    {
        CGRect contentRect = CGRectMake(5.0f, 5.0f, 30.0f, 30.0f);
        contentView = [[WheelBubble alloc] initWithFrame:contentRect];
    }
    contentView.imageView.backgroundColor = [GameColors bubbleColorFlyersWithAlpha:1.0f];
    UIColor* borderColor = [GameColors borderColorFlyersWithAlpha:1.0f];
    [PogUIUtility setCircleForView:contentView.imageView
                   withBorderWidth:kBubbleBorderWidth
                       borderColor:borderColor
                    rasterizeScale:2.0f];
    if(index < [_playerFlyers count])
    {
        Flyer* curFlyer = [_playerFlyers objectAtIndex:index];
        NSString* flyerTypeName = [[FlyerTypes getInstance] topImgForFlyerTypeAtIndex:[curFlyer flyerTypeIndex]];
        NSString* imageName = [[FlyerLabFactory getInstance] topImageForFlyerTypeNamed:flyerTypeName tier:[curFlyer curUpgradeTier] colorIndex:[curFlyer curColor]];
        UIImage* image = [[ImageManager getInstance] getImage:imageName];
        [contentView.imageView setImage:image];
        
        Flyer* flyer = [_playerFlyers objectAtIndex:index];
        if([flyer gameEvent])
        {
            [[GameAnim getInstance] refreshImageView:contentView.exclamationView withClipNamed:@"alert_flyer"];
            [contentView.exclamationView startAnimating];
            [contentView.exclamationView setHidden:NO];
        }
        else
        {
            [contentView.exclamationView stopAnimating];
            [contentView.exclamationView setAnimationImages:nil];
            [contentView.exclamationView setHidden:YES];
        }
    }
    else
    {
        unsigned int lookupIndex = index - [_playerFlyers count];
        if(lookupIndex < [purchaseables count])
        {
            unsigned int flyerTypeIndex = [[purchaseables objectAtIndex:lookupIndex] unsignedIntValue];
            FlyerType* flyerType = [[FlyerTypes getInstance] getFlyerTypeAtIndex:flyerTypeIndex];
            NSString* flyerTypeName = [flyerType topimg];
            NSString* imageName = [[FlyerLabFactory getInstance] topImageForFlyerTypeNamed:flyerTypeName tier:1 colorIndex:0];
            UIImage* image = [[ImageManager getInstance] getGrayscaleImage:imageName fallbackNamed:imageName];
            [contentView.imageView setImage:image];
        }
    }

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
            _previewMap.isPreviewMap = YES;
            
        }
    }
    return result;
}

- (UIColor*) previewColorForWheel:(WheelControl *)wheel
{
    UIColor* result = [GameColors bubbleBgColorWithAlpha:1.0f];
    return result;
}

- (UIColor*) previewBorderColorForWheel:(WheelControl *)wheel
{
    UIColor* result = [GameColors bubbleColorFlyersWithAlpha:1.0f];
    return result;
}

- (UIColor*) previewButtonColorForWheel:(WheelControl *)wheel
{
    UIColor* result = [GameColors bubbleColorScanWithAlpha:1.0f];
    return result;
}

- (UIColor*) previewButtonBorderColorForWheel:(WheelControl *)wheel
{
    UIColor* result = [GameColors bubbleColorFlyersWithAlpha:1.0f];
    return result;
}

static const float kPreviewImageInset = 25.0f;
static const float kPreviewImageYOffset = -0.25f;
- (CGRect) previewImageFrameForWheel:(WheelControl*)wheel inParentFrame:(CGRect)parentCircleFrame
{
    CGRect imageFrame = CGRectInset(parentCircleFrame, kPreviewImageInset, kPreviewImageInset);
    float yOffset = kPreviewImageYOffset * imageFrame.size.height;
    imageFrame.origin = CGPointMake(imageFrame.origin.x, imageFrame.origin.y + yOffset);
    return imageFrame;
}

#pragma mark - WheelProtocol
- (void) wheel:(WheelControl*)wheel didMoveTo:(unsigned int)index
{
    [self refreshPreviewForWheel:wheel atIndex:index];
}

- (void) wheel:(WheelControl*)wheel didSettleAt:(unsigned int)index
{
    // do nothing
}

- (void) wheel:(WheelControl*)wheel didPressOkOnIndex:(unsigned int)index
{
    if([_playerFlyers count] > index)
    {
        Flyer* curFlyer = [_playerFlyers objectAtIndex:index];
        [[GameManager getInstance] wheel:wheel commitOnFlyer:curFlyer];
    }
    else if(kGameStateGameLoop == [[GameManager getInstance] gameState])
    {
        NSArray* purchaseables = [self getPurchaseableFlyerTypeIndices];
        unsigned int lookupIndex = index - [_playerFlyers count];
        if(lookupIndex < [purchaseables count])
        {
            unsigned int flyerTypeIndex = [[purchaseables objectAtIndex:lookupIndex] unsignedIntValue];
            FlyerType* flyerType = [[FlyerTypes getInstance] getFlyerTypeAtIndex:flyerTypeIndex];
            FlyerBuyConfirmScreen* next = [[FlyerBuyConfirmScreen alloc] initWithFlyerType:flyerType];
            [[GameManager getInstance].gameViewController showModalNavViewController:next completion:nil];
        }
        else
        {
            [[GameManager getInstance] popGameStateToLoop];
        }
    }
    else
    {
        [[GameManager getInstance] popGameStateToLoop];        
    }
}

- (void) wheel:(WheelControl *)wheel didPressCloseOnIndex:(unsigned int)index
{
    // inform GameManager to pop back to idle
    [[GameManager getInstance] popGameStateToLoop];
}

- (void) wheel:(WheelControl*)wheel willShowAtIndex:(unsigned int)index
{
    // clear cache
    _cachedPurchaseables = nil;
    
    [self wheel:wheel didMoveTo:index];

    // refresh previewMap
    [_previewMap removeAllAnnotations];
    for(Flyer* cur in _playerFlyers)
    {
        [_previewMap addAnnotationForFlyer:cur];
    }
}

- (void) wheel:(WheelControl*)wheel willHideAtIndex:(unsigned int)index
{
    [_previewMap stopTrackingAnnotation];
    [_previewMap removeAllAnnotations];
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
