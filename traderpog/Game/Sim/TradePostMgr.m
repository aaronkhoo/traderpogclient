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
static const float kPreviewPostWidth = 120.0f;
static const float kPreviewPostHeight = 120.0f;
static NSString* const kNPCPost_prepend = @"NPCPost";

@interface TradePostMgr ()
{
    NSMutableDictionary* _foundPosts;
    NSMutableDictionary* _activePosts;
    NSMutableArray* _myPostSlots;
    NSMutableDictionary* _npcPosts;
    
    // Posts found on flyers, but not in retrieved lists
    NSMutableArray* _danglingPosts;
    
    // for NPC posts generation
    unsigned int _npcPostIndex;
    
    // User trade post in the midst of being generated
    MyTradePost* _tempTradePost;
}
@property (nonatomic,strong) NSMutableDictionary* foundPosts;
@property (nonatomic,strong) NSMutableDictionary* activePosts;
@property (nonatomic,strong) NSMutableArray* myPostSlots;
@property (nonatomic,strong) NSMutableDictionary* npcPosts;

- (BOOL) post:(TradePost*)post isWithinDistance:(float)distance fromCoord:(CLLocationCoordinate2D)coord;
@end

@implementation TradePostMgr
@synthesize foundPosts = _foundPosts;
@synthesize activePosts = _activePosts;
@synthesize myPostSlots = _myPostSlots;
@synthesize npcPosts = _npcPosts;
@synthesize delegate = _delegate;
@synthesize delegateScan = _delegateScan;
@synthesize delegateDanglingPosts = _delegateDanglingPosts;

- (id) init
{
    self = [super init];
    if(self)
    {
        _activePosts = [NSMutableDictionary dictionaryWithCapacity:10];
        _myPostSlots = [NSMutableArray arrayWithCapacity:6];
        _npcPosts = [NSMutableDictionary dictionaryWithCapacity:10];
        _foundPosts = [NSMutableDictionary dictionaryWithCapacity:10];
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
    
    for (ForeignTradePost* post in [self.foundPosts allValues])
    {
        [[[GameManager getInstance] gameViewController].mapControl addAnnotationForTradePost:post];
        if([postIdsWithFlyers stringArrayContainsString:[post postId]])
        {
            post.hasFlyer = YES;
        }
    }
}

- (BOOL) isNPCPostId:(NSString*)postid
{
    // Check if the current postid is an NPC one, i.e. it's of the form "NPCPost<some_num>"
    NSRange range = [postid rangeOfString:kNPCPost_prepend];
    return (range.location != NSNotFound);
}

- (NPCTradePost*) newNPCTradePostAtCoord:(CLLocationCoordinate2D)coord
                          bucks:(unsigned int)bucks
{
    NSString* postId = [NSString stringWithFormat:@"%@%d", kNPCPost_prepend, _npcPostIndex];
    
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
        result = [self.foundPosts objectForKey:postId];
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
    
    // query for other tradeposts (not belonging to self or friends)
    for(ForeignTradePost* cur in self.foundPosts.allValues)
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

    return result;
}

- (BOOL) resolveDanglingPosts
{
    BOOL done = TRUE;
    _danglingPosts = [[FlyerMgr getInstance] unknownTradePostsFromFlyers];
    if (_danglingPosts.count > 0)
    {
        done = FALSE;
        NSString* postid = [_danglingPosts objectAtIndex:0];
        [_danglingPosts removeObjectAtIndex:0];
        [self retrieveSpecificPostFromServer:postid];
    }
    return done;
}

- (void) flushForeignPosts
{
    // Clear all found posts
    [_foundPosts removeAllObjects];
}

#pragma mark - retrieve data from server
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
                    NSLog(@"Retrieved from retrievePostsFromServer: %@", responseObject);
                    [_myPostSlots removeAllObjects];
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

- (void) retrieveSpecificPostFromServer:(NSString*)postid
{
    // make a get request
    AFHTTPClient* httpClient = [[AFClientManager sharedInstance] traderPog];
    NSString* postUrl = [NSString stringWithFormat:@"posts/%@.json", postid];
    [httpClient getPath:postUrl
             parameters:nil
                success:^(AFHTTPRequestOperation *operation, id responseObject){
                    NSLog(@"Retrieved post %@ from server: %@", postid, responseObject);
                    ForeignTradePost* current = [[ForeignTradePost alloc] initWithDictionary:responseObject];
                    [self.foundPosts setObject:current forKey:current.postId];
                    if (_danglingPosts.count > 0)
                    {
                        NSString* postid = [_danglingPosts objectAtIndex:0];
                        [_danglingPosts removeObjectAtIndex:0];
                        [self retrieveSpecificPostFromServer:postid];
                    }
                    else
                    {
                        [self.delegate didCompleteHttpCallback:kTradePostMgr_ReceiveSinglePost, TRUE];   
                    }
                }
                failure:^(AFHTTPRequestOperation* operation, NSError* error){
                    NSLog(@"Failed to retrieve post %@ from server", postid);
                    if (_danglingPosts.count > 0)
                    {
                        NSString* postid = [_danglingPosts objectAtIndex:0];
                        [_danglingPosts removeObjectAtIndex:0];
                        [self retrieveSpecificPostFromServer:postid];
                    }
                    else
                    {
                        [self.delegate didCompleteHttpCallback:kTradePostMgr_ReceiveSinglePost, FALSE];
                    }
                }
     ];
}

- (void) createFoundPosts:(id)responseObject
{
    for (NSDictionary* post in responseObject)
    {
        NSString* postId = [NSString stringWithFormat:@"%d", [[post valueForKeyPath:kKeyTradePostId] integerValue]];
        TradePost* foundPost = [self getTradePostWithId:postId];
        if (!foundPost)
        {
            ForeignTradePost* current = [[ForeignTradePost alloc] initWithDictionary:post];
            [self.foundPosts setObject:current forKey:current.postId];
        }
    }
}

- (void) scanForTradePosts:(CLLocationCoordinate2D)coord
{
    // make a get request
    AFHTTPClient* httpClient = [[AFClientManager sharedInstance] traderPog];
    NSString *userId = [NSString stringWithFormat:@"%d", [[Player getInstance] playerId]];
    NSString *latitude = [NSString stringWithFormat:@"%f", coord.latitude];
    NSString *longitude = [NSString stringWithFormat:@"%f", coord.longitude];
    
    [httpClient setDefaultHeader:@"traderpog-latitude" value:latitude];
    [httpClient setDefaultHeader:@"traderpog-longitude" value:longitude];
    [httpClient setDefaultHeader:@"user-id" value:userId];
    [httpClient getPath:@"posts/scan"
             parameters:nil
                success:^(AFHTTPRequestOperation *operation, id responseObject){
                    NSLog(@"Retrieved from scanForTradePosts: %@", responseObject);
                    [self createFoundPosts:responseObject];
                    [self.delegateScan didCompleteHttpCallback:kTradePostMgr_ScanForPosts, TRUE];
                }
                failure:^(AFHTTPRequestOperation* operation, NSError* error){
                    [self.delegateScan didCompleteHttpCallback:kTradePostMgr_ScanForPosts, FALSE];
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

    contentView.backgroundColor = [GameColors bubbleBgColorWithAlpha:1.0f];
    if([NSNull null] == [self.myPostSlots objectAtIndex:index])
    {
        UIImage* image = [[ImageManager getInstance] getImage:@"bubble_postmark_g.png" fallbackNamed:@"bubble_postmark_g.png"];
        [contentView.imageView setImage:image];
    }
    else
    {
        UIImage* image = [[ImageManager getInstance] getImage:@"b_flyerlab.png" fallbackNamed:@"b_flyerlab.png"];
        [contentView.imageView setImage:image];
    }
    UIColor* borderColor = [GameColors borderColorPostsWithAlpha:1.0f];
    [PogUIUtility setCircleForView:contentView
                   withBorderWidth:kPostBubbleBorderWidth
                       borderColor:borderColor
                    rasterizeScale:1.5f];
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
            result.userInteractionEnabled = NO;
            
            CGSize previewSize = wheel.previewCircle.bounds.size;
            CGRect imageRect = CGRectMake(0.5f * (previewSize.width - kPreviewPostWidth),
                                          (0.5f * (previewSize.height - kPreviewPostHeight)) - (0.4f * kPreviewPostHeight),
                                          kPreviewPostWidth,
                                          kPreviewPostHeight);
            
            wheel.previewImageView.frame = imageRect;
            UIImage* image = [[ImageManager getInstance] getImage:[initPost imgPath] fallbackNamed:@"b_flyerlab.png"];
            [wheel.previewImageView setImage:image];
            [wheel.previewImageView setHidden:NO];

            // label
            [wheel.previewLabel setNumberOfLines:1];
            [wheel.previewLabel setText:@"Reverse Geocode"];
            [wheel.previewLabel setFont:[UIFont fontWithName:@"Marker Felt" size:19.0f]];
        }
    }
    return result;
}

- (UIColor*) previewColorForWheel:(WheelControl *)wheel
{
    UIColor* result = [UIColor clearColor];//[GameColors bubbleBgColorWithAlpha:1.0f];
    return result;
}

- (UIColor*) previewBorderColorForWheel:(WheelControl *)wheel
{
    UIColor* result = [GameColors bubbleColorPostsWithAlpha:1.0f];
    return result;
}

- (UIColor*) previewButtonColorForWheel:(WheelControl *)wheel
{
    UIColor* result = [GameColors bubbleColorScanWithAlpha:1.0f];
    return result;
}

- (UIColor*) previewButtonBorderColorForWheel:(WheelControl *)wheel
{
    UIColor* result = [GameColors bubbleColorPostsWithAlpha:1.0f];
    return result;
}

#pragma mark - WheelProtocol
- (void) wheel:(WheelControl*)wheel didMoveTo:(unsigned int)index
{
    index = MIN(index, kMyPostSlotNum-1);
    if([NSNull null] != [self.myPostSlots objectAtIndex:index])
    {
        // map
        TradePost* cur = [self.myPostSlots objectAtIndex:index];
        [_previewMap centerOn:[cur coord] animated:NO];
        _previewMap.view.showsUserLocation = NO;
        _previewMap.view.userTrackingMode = MKUserTrackingModeNone;

        // label
        [wheel.previewLabel setNumberOfLines:1];
        [wheel.previewLabel setText:@"Reverse Geocode"];
        [wheel.previewLabel setFont:[UIFont fontWithName:@"Marker Felt" size:19.0f]];

        // image
        CGSize previewSize = wheel.previewCircle.bounds.size;
        CGRect imageRect = CGRectMake(0.5f * (previewSize.width - kPreviewPostWidth),
                                      (0.5f * (previewSize.height - kPreviewPostHeight)) - (0.4f * kPreviewPostHeight),
                                      kPreviewPostWidth,
                                      kPreviewPostHeight);
        wheel.previewImageView.frame = imageRect;
        UIImage* image = [[ImageManager getInstance] getImage:[cur imgPath] fallbackNamed:@"b_flyerlab.png"];
        [wheel.previewImageView setImage:image];
        [wheel.previewImageView setHidden:NO];
        [wheel.previewImageView setBackgroundColor:[UIColor clearColor]];
    }
    else if(kMyPostSlotFreeEnd > index)
    {
        // free slots
        
        // map
        _previewMap.view.showsUserLocation = YES;
        _previewMap.view.userTrackingMode = MKUserTrackingModeFollow;
        
        // label
        [wheel.previewLabel setNumberOfLines:1];
        [wheel.previewLabel setText:@"Create Post"];
        [wheel.previewLabel setFont:[UIFont fontWithName:@"Marker Felt" size:19.0f]];

        // image
        [wheel.previewImageView setHidden:YES];
    }
    else
    {        
        // member slots
        
        // map
        _previewMap.view.showsUserLocation = NO;
        _previewMap.view.userTrackingMode = MKUserTrackingModeNone;
        
        // label
        [wheel.previewLabel setNumberOfLines:2];
        [wheel.previewLabel setText:@"Member Only\nJoin NOW!"];
        [wheel.previewLabel setFont:[UIFont fontWithName:@"Marker Felt" size:15.0f]];

        // image
        wheel.previewImageView.frame = wheel.previewCircle.bounds;
        UIImage* bgImage = [[ImageManager getInstance] getImage:@"icon_none_member.png" fallbackNamed:@"icon_none_member.png"];
        [wheel.previewImageView setImage:bgImage];
        [wheel.previewImageView setHidden:NO];
        [wheel.previewImageView setBackgroundColor:[GameColors bubbleBgColorWithAlpha:1.0f]];
    }
}

- (void) wheel:(WheelControl*)wheel didSettleAt:(unsigned int)index
{
    // do nothing
}

- (void) wheel:(WheelControl*)wheel didPressOkOnIndex:(unsigned int)index
{
    index = MIN(index, kMyPostSlotNum-1);
    if([NSNull null] != [self.myPostSlots objectAtIndex:index])
    {
        TradePost* cur = [self.myPostSlots objectAtIndex:index];
        [[GameManager getInstance] wheel:wheel commitOnTradePost:cur];
    }
    else if(kMyPostSlotFreeEnd > index)
    {
        NSLog(@"Create Post");
    }
    else
    {
        NSLog(@"Member Create Post");
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
