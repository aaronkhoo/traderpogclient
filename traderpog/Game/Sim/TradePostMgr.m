//
//  TradePostMgr.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/13/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "AFClientManager.h"
#import "GameManager.h"
#import "Player.h"
#import "TradePostMgr.h"
#import "TradePost.h"
#import "TradeItem.h"
#import "TradeItemType.h"
#import "TradeItemTypes.h"
#import "WheelControl.h"
#import "WheelBubble.h"
#import "PogUIUtility.h"
#import "MapControl.h"
#import "CLLocation+Pog.h"
#import "BeaconMgr.h"

static double const refreshTime = -(60 * 15);

@interface TradePostMgr ()
{
    NSMutableDictionary* _activePosts;
    NSMutableDictionary* _npcPosts;
    
    // for NPC posts generation
    unsigned int _npcPostIndex;
    
    // User trade post in the midst of being generated
    TradePost* _tempTradePost;
    
    // for wheel
    MapControl* _previewMap;
}
@property (nonatomic,strong) NSMutableDictionary* activePosts;
@property (nonatomic,strong) NSMutableDictionary* npcPosts;

- (BOOL) post:(TradePost*)post isWithinDistance:(float)distance fromCoord:(CLLocationCoordinate2D)coord;

- (void) createPlaceholderBeaconPosts;
@end

@implementation TradePostMgr
@synthesize activePosts = _activePosts;
@synthesize npcPosts = _npcPosts;
@synthesize delegate = _delegate;

- (id) init
{
    self = [super init];
    if(self)
    {
        _activePosts = [NSMutableDictionary dictionaryWithCapacity:10];
        _npcPosts = [NSMutableDictionary dictionaryWithCapacity:10];
        _npcPostIndex = 0;
        _tempTradePost = nil;
        _previewMap = nil;
    }
    return self;
}

- (BOOL) needsRefresh
{
    return (!_lastUpdate) || ([_lastUpdate timeIntervalSinceNow] < refreshTime);
}

- (NSInteger) postsCount
{
    return _activePosts.count;
}

- (void) annotatePostsOnMap
{
    for (id key in _activePosts)
    {
        TradePost* post = [_activePosts objectForKey:key];
        [[[GameManager getInstance] gameViewController].mapControl addAnnotationForTradePost:post];
    }
}

- (TradePost*) newNPCTradePostAtCoord:(CLLocationCoordinate2D)coord
                          sellingItem:(TradeItemType*)itemType
{
    NSString* postId = [NSString stringWithFormat:@"NPCPost%d", _npcPostIndex];
    ++_npcPostIndex;
    TradePost* newPost = [[TradePost alloc] initWithPostId:postId coordinate:coord itemType:itemType];
    [self.npcPosts setObject:newPost forKey:postId];
    return newPost;
}

- (BOOL) newTradePostAtCoord:(CLLocationCoordinate2D)coord 
                              sellingItem:(TradeItemType *)itemType
{
    if (_tempTradePost == nil)
    {
        TradePost* newPost = [[TradePost alloc] initWithCoordinates:coord itemType:itemType];
        [newPost setDelegate:[TradePostMgr getInstance]];
        _tempTradePost = newPost;
        [_tempTradePost createNewPostOnServer];
        return TRUE;
    }
    
    return FALSE;
}

- (void) setTempPostToActive
{
    if (_tempTradePost)
    {
        // The temp TradePost has been successfully uploaded to the server, so move it
        // to the active list.
        [self.activePosts setObject:_tempTradePost forKey:_tempTradePost.postId];
        
        // Add this tradepost as an annotation to the mapcontrol instance if the map control has already
        // been created. If it hasn't, then log and skip this step. It's possible that the mapcontrol
        // doesn't exist yet during the startup flow. This will be taken care of properly, see GameManager
        // for more details. 
        if ([[GameManager getInstance] gameViewController].mapControl)
        {
            [[[GameManager getInstance] gameViewController].mapControl addAnnotationForTradePost:_tempTradePost];   
        }
        else 
        {
            NSLog(@"Map control has not been initialized!");
        }
        _tempTradePost = nil;
    }
}

- (TradePost*) getTradePostWithId:(NSString *)postId
{
    TradePost* result = [self.activePosts objectForKey:postId];
    if(!result)
    {
        result = [self.npcPosts objectForKey:postId];
    }
    return result;
}

- (TradePost*) getFirstTradePost
{
    id key = [[_activePosts allKeys] objectAtIndex:0];
    return [_activePosts objectForKey:key];
}

- (NSMutableArray*) getTradePostsAtCoord:(CLLocationCoordinate2D)coord 
                           radius:(float)radius 
                           maxNum:(unsigned int)maxNum
{
    NSMutableArray* result = [NSMutableArray arrayWithCapacity:5];
    
    // HACK
    // TODO: implement query from server
    // HACK
    
    // query active posts
    unsigned int num = 0;
    for(TradePost* cur in self.activePosts.allValues)
    {
        if([self post:cur isWithinDistance:radius fromCoord:coord])
        {
            [result addObject:cur];
            ++num;
            if(num >= maxNum)
            {
                break;
            }
        }
    }
    
    // query npc posts
    for(TradePost* cur in self.npcPosts.allValues)
    {
        if([self post:cur isWithinDistance:radius fromCoord:coord])
        {
            [result addObject:cur];
            ++num;
            if(num >= maxNum)
            {
                break;
            }
        }        
    }
    
    return result;
}

- (void) createItemsArray:(id)responseObject
{
    for (NSDictionary* item in responseObject)
    {
        TradePost* current = [[TradePost alloc] initWithDictionary:item];
        [self.activePosts setObject:current forKey:current.postId];
    }
    
    // HACK
    // remove after retrieve from server of friends posts is implemented
    [self createPlaceholderBeaconPosts];
    // HACK
}

- (void) retrievePostsFromServer
{
    // make a get request
    AFHTTPClient* httpClient = [[AFClientManager sharedInstance] traderPog];
    NSString *userId = [NSString stringWithFormat:@"%d", [[Player getInstance] id]];
    [httpClient setDefaultHeader:@"user_id" value:userId];
    [httpClient getPath:@"posts.json" 
             parameters:nil
                success:^(AFHTTPRequestOperation *operation, id responseObject){                     
                    NSLog(@"Retrieved: %@", responseObject);
                    [self createItemsArray:responseObject];
                    _lastUpdate = [NSDate date];
                    [self.delegate didCompleteHttpCallback:kTradePostMgr_ReceivePosts, TRUE];
                }
                failure:^(AFHTTPRequestOperation* operation, NSError* error){
                    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Server Failure"
                                                                      message:@"Unable to create retrieve items. Please try again later."
                                                                     delegate:nil
                                                            cancelButtonTitle:@"OK"
                                                            otherButtonTitles:nil];
                    
                    [message show];
                    [self.delegate didCompleteHttpCallback:kTradePostMgr_ReceivePosts, FALSE];
                }
     ];
    [httpClient setDefaultHeader:@"user_id" value:nil];
}

#pragma mark - internal methods
- (BOOL) post:(TradePost*)post isWithinDistance:(float)distance fromCoord:(CLLocationCoordinate2D)coord
{
    BOOL result = NO;
    
    CLLocation* center = [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];
    CLLocation* postLoc = [[CLLocation alloc] initWithLatitude:post.coord.latitude longitude:post.coord.longitude];
    CLLocationDistance dist = [postLoc distanceFromLocation:center];
    if(dist <= distance)
    {
        result = YES;
    }
    
    return result;
}

// HACK
// remove when retrieve from server is implemented
- (void) createPlaceholderBeaconPosts
{
    NSArray* itemTypes = [[TradeItemTypes getInstance] getItemTypesForTier:1];
    if(itemTypes && [itemTypes count])
    {
        TradeItemType* itemType = [itemTypes objectAtIndex:0];
        NSString* postId0 = [NSString stringWithFormat:@"PlaceholderFriendPost%d", 0];
        TradePost* newPost0 = [[TradePost alloc] initWithPostId:postId0
                                                     coordinate:[CLLocation london].coordinate
                                                       itemType:itemType];
        newPost0.isOwnPost = NO;
        newPost0.isNPCPost = NO;
        [self.activePosts setObject:newPost0 forKey:postId0];

        NSString* postId1 = [NSString stringWithFormat:@"PlaceholderFriendPost%d", 1];
        TradePost* newPost1 = [[TradePost alloc] initWithPostId:postId1
                                                     coordinate:[CLLocation penang].coordinate
                                                       itemType:itemType];
        newPost1.isOwnPost = NO;
        newPost1.isNPCPost = NO;
        [self.activePosts setObject:newPost1 forKey:postId1];
    }
    
    [[BeaconMgr getInstance] createPlaceholderBeacons];
}
// HACK

#pragma mark - HttpCallbackDelegate
- (void) didCompleteHttpCallback:(NSString*)callName, BOOL success
{
    if (success)
    {
        [self setTempPostToActive];
    }
    [[GameManager getInstance] selectNextGameUI];
}

#pragma mark - WheelDataSource
- (unsigned int) numItemsInWheel:(WheelControl *)wheel
{
    unsigned int num = [_activePosts count];
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
    if([_activePosts count])
    {
        if(_previewMap)
        {
            result = [_previewMap view];
        }
        else
        {
            CGRect superFrame = wheel.previewView.bounds;
            result = [[MKMapView alloc] initWithFrame:superFrame];
            index = MIN(index, [_activePosts count]-1);
            TradePost* initPost = [_activePosts.allValues objectAtIndex:index];
            _previewMap = [[MapControl alloc] initWithMapView:result
                                                    andCenter:[initPost coord]];
        }
    }
    return result;
}

#pragma mark - WheelProtocol
- (void) wheelDidMoveTo:(unsigned int)index
{
    NSLog(@"wheel moved to %d",index);
}

- (void) wheelDidSettleAt:(unsigned int)index
{
    if([_activePosts count])
    {
        index = MIN(index, [_activePosts count]-1);
        TradePost* cur = [_activePosts.allValues objectAtIndex:index];
        [_previewMap centerOn:[cur coord] animated:YES];
    }
}

- (void) wheel:(WheelControl*)wheel didPressOkOnIndex:(unsigned int)index
{
    if([_activePosts count])
    {
        index = MIN(index, [_activePosts count]-1);
        TradePost* cur = [_activePosts.allValues objectAtIndex:index];
        [wheel.superMap centerOn:[cur coord] animated:YES];
    }
}



#pragma mark - Singleton
static TradePostMgr* singleton = nil;
+ (TradePostMgr*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
            if (!singleton)
            {
                singleton = [[TradePostMgr alloc] init];
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
