//
//  TradePostMgr.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/13/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "AFClientManager.h"
#import "ForeignTradePost.h"
#import "GameManager.h"
#import "MyTradePost.h"
#import "NPCTradePost.h"
#import "Player.h"
#import "TradePostMgr.h"
#import "TradeItem.h"
#import "TradeItemType.h"
#import "TradeItemTypes.h"
#import "WheelControl.h"
#import "WheelBubble.h"
#import "PogUIUtility.h"
#import "MapControl.h"
#import "CLLocation+Pog.h"
#import "NSArray+Pog.h"
#import "BeaconMgr.h"
#import "FlyerMgr.h"
#import "GameColors.h"
#import "ImageManager.h"

enum _MyPostSlots
{
    kMyPostSlotFreeBegin = 0,
    kMyPostSlotFree0 = kMyPostSlotFreeBegin,
    kMyPostSlotFree1,
    kMyPostSlotFree2,
    kMyPostSlotFreeEnd,
    kMyPostSlotMemberBegin = kMyPostSlotFreeEnd,
    kMyPostSlotMember0 = kMyPostSlotMemberBegin,
    kMyPostSlotMember1,
    kMyPostSlotMember2,
    kMyPostSlotMemberEnd,
    
    kMyPostSlotNum = kMyPostSlotMemberEnd
};

static double const refreshTime = -(60 * 15);
static const float kPostBubbleBorderWidth = 1.5f;

@interface TradePostMgr ()
{
    NSMutableDictionary* _activePosts;
    NSMutableArray* _myPostSlots;
    NSMutableDictionary* _npcPosts;
    
    // for NPC posts generation
    unsigned int _npcPostIndex;
    
    // User trade post in the midst of being generated
    MyTradePost* _tempTradePost;
}
@property (nonatomic,strong) NSMutableDictionary* activePosts;
@property (nonatomic,strong) NSMutableArray* myPostSlots;
@property (nonatomic,strong) NSMutableDictionary* npcPosts;

- (BOOL) post:(TradePost*)post isWithinDistance:(float)distance fromCoord:(CLLocationCoordinate2D)coord;
@end

@implementation TradePostMgr
@synthesize activePosts = _activePosts;
@synthesize myPostSlots = _myPostSlots;
@synthesize npcPosts = _npcPosts;
@synthesize delegate = _delegate;

- (id) init
{
    self = [super init];
    if(self)
    {
        _activePosts = [NSMutableDictionary dictionaryWithCapacity:10];
        _myPostSlots = [NSMutableArray arrayWithCapacity:6];
        _npcPosts = [NSMutableDictionary dictionaryWithCapacity:10];
        _npcPostIndex = 0;
        _tempTradePost = nil;
        _previewMap = nil;
        _lastUpdate = nil;
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

- (BOOL) isBeaconActive
{
    for (MyTradePost* post in [_activePosts allValues])
    {
        if ([post beaconActive])
        {
            return TRUE;
        }
    }
    return FALSE;
}

// this method performs linkage on variables that need to be resolved when
// all data in all managers (FlyerMgr, TradePostMgr, etc.) has been loaded
// specifically, it adds all the loaded posts as annotations in the game map, and it
// initializes the hasFlyer variable in each post;
- (void) annotatePostsOnMap
{
    NSArray* postIdsWithFlyers = [[FlyerMgr getInstance] tradePostIdsWithFlyers];
    
    for (MyTradePost* post in [_activePosts allValues])
    {
        [[[GameManager getInstance] gameViewController].mapControl addAnnotationForTradePost:post];
        if([postIdsWithFlyers stringArrayContainsString:[post postId]])
        {
            post.hasFlyer = YES;
        }
    }
    
    for (NPCTradePost* post in [self.npcPosts allValues])
    {
        [[[GameManager getInstance] gameViewController].mapControl addAnnotationForTradePost:post];        
        if([postIdsWithFlyers stringArrayContainsString:[post postId]])
        {
            post.hasFlyer = YES;
        }
    }
}

- (NPCTradePost*) newNPCTradePostAtCoord:(CLLocationCoordinate2D)coord
                          bucks:(unsigned int)bucks
{
    NSString* postId = [NSString stringWithFormat:@"NPCPost%d", _npcPostIndex];
    
    ++_npcPostIndex;
    NPCTradePost* newPost = [[NPCTradePost alloc] initWithPostId:postId
                                                      coordinate:coord
                                                           bucks:bucks];
    [self.npcPosts setObject:newPost forKey:postId];
    return newPost;
}

- (BOOL) newTradePostAtCoord:(CLLocationCoordinate2D)coord 
                 sellingItem:(TradeItemType *)itemType
{
    if (_tempTradePost == nil)
    {
        MyTradePost* newPost = [[MyTradePost alloc] initWithCoordinates:coord itemType:itemType];
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
    if(!result)
    {
        // friends posts are in BeaconMgr
        result = [[BeaconMgr getInstance].activeBeacons objectForKey:postId];
    }
    return result;
}

- (MyTradePost*) getFirstMyTradePost
{
    id key = [[_activePosts allKeys] objectAtIndex:0];
    return [_activePosts objectForKey:key];
}

- (NSMutableArray*) getTradePostsAtCoord:(CLLocationCoordinate2D)coord 
                           radius:(float)radius 
                           maxNum:(unsigned int)maxNum
{
    NSMutableArray* result = [NSMutableArray arrayWithCapacity:5];
        
    // query active posts
    unsigned int num = 0;
    for(MyTradePost* cur in self.activePosts.allValues)
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
    for(NPCTradePost* cur in self.npcPosts.allValues)
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
    
    // query friends posts
    for(ForeignTradePost* cur in [BeaconMgr getInstance].activeBeacons.allValues)
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

- (void) createPostsArray:(id)responseObject
{
    for (NSDictionary* post in responseObject)
    {
        MyTradePost* current = [[MyTradePost alloc] initWithDictionary:post];
        [self.activePosts setObject:current forKey:current.postId];
        [self.myPostSlots addObject:current];
    }
    
    if([self.myPostSlots count] < kMyPostSlotNum)
    {
        unsigned int index = [self.myPostSlots count];
        while(index < kMyPostSlotNum)
        {
            [self.myPostSlots addObject:[NSNull null]];
            ++index;
        }
    }
}

- (void) retrievePostsFromServer
{
    // make a get request
    AFHTTPClient* httpClient = [[AFClientManager sharedInstance] traderPog];
    NSString *userId = [NSString stringWithFormat:@"%d", [[Player getInstance] playerId]];
    [httpClient setDefaultHeader:@"user_id" value:userId];
    [httpClient getPath:@"posts.json" 
             parameters:nil
                success:^(AFHTTPRequestOperation *operation, id responseObject){                     
                    NSLog(@"Retrieved: %@", responseObject);
                    [self createPostsArray:responseObject];
                    _lastUpdate = [NSDate date];
                    [self.delegate didCompleteHttpCallback:kTradePostMgr_ReceivePosts, TRUE];
                }
                failure:^(AFHTTPRequestOperation* operation, NSError* error){
                    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Server Failure"
                                                                      message:@"Unable to create retrieve posts. Please try again later."
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
    unsigned int num = [self.myPostSlots count];
    return num;
}

- (WheelBubble*) wheel:(WheelControl *)wheel bubbleAtIndex:(unsigned int)index
{
    WheelBubble* contentView = [wheel dequeueResuableBubble];
    if(nil == contentView)
    {
        CGRect contentRect = CGRectMake(5.0f, 5.0f, 30.0f, 30.0f);
        contentView = [[WheelBubble alloc] initWithFrame:contentRect];
    }

    if([NSNull null] == [self.myPostSlots objectAtIndex:index])
    {
        contentView.backgroundColor = [UIColor grayColor];
        UIImage* image = [[ImageManager getInstance] getImage:@"bubble_postmark_g.png" fallbackNamed:@"bubble_postmark_g.png"];
        [contentView.imageView setImage:image];
    }
    else
    {
        contentView.backgroundColor = [UIColor redColor];
        UIImage* image = [[ImageManager getInstance] getImage:@"b_flyerlab.png" fallbackNamed:@"b_flyerlab.png"];
        [contentView.imageView setImage:image];
    }
    
    UIColor* borderColor = [GameColors borderColorPostsWithAlpha:1.0f];
    [PogUIUtility setCircleForView:contentView
                   withBorderWidth:kPostBubbleBorderWidth
                       borderColor:borderColor];
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
        [[GameManager getInstance] wheel:wheel commitOnTradePost:cur];
    }
}

- (void) wheel:(WheelControl *)wheel didPressCloseOnIndex:(unsigned int)index
{
    // inform GameManager to pop back to idle
    [[GameManager getInstance] popGameStateToLoop];
}

- (void) wheel:(WheelControl*)wheel willShowAtIndex:(unsigned int)index
{
    // do nothing
}

- (void) wheel:(WheelControl*)wheel willHideAtIndex:(unsigned int)index
{
    // do nothing
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
