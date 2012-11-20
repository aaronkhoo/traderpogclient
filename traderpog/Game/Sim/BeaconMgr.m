//
//  BeaconMgr.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "AFClientManager.h"
#import "BeaconMgr.h"
#import "ForeignTradePost.h"
#import "WheelControl.h"
#import "WheelBubble.h"
#import "PogUIUtility.h"
#import "Player.h"
#import "FlyerMgr.h"
#import "Flyer.h"
#import "NSArray+Pog.h"
#import "GameColors.h"
#import "ImageManager.h"
#import "UrlImage.h"

static NSUInteger kBeaconPreviewZoomLevel = 8;
static double const refreshTime = -(60 * 15);
static const unsigned int kBeaconNum = 10;
static const float kBubbleBorderWidth = 1.5f;

@interface BeaconMgr ()
{
    NSMutableDictionary* _cachedImages;
}
@end

@implementation BeaconMgr
@synthesize activeBeacons = _activeBeacons;
@synthesize previewMap = _previewMap;
@synthesize delegate = _delegate;

- (id) init
{
    self = [super init];
    if(self)
    {
        _activeBeacons = [NSMutableDictionary dictionaryWithCapacity:10];
        _lastUpdate = nil;
        _cachedImages = [NSMutableDictionary dictionaryWithCapacity:10];
    }
    return self;
}

- (void) resetRefresh
{
    _lastUpdate = nil;
}

- (BOOL) needsRefresh
{
    return ([[Player getInstance] isFacebookConnected]) &&
            ((!_lastUpdate) ||
            ([_lastUpdate timeIntervalSinceNow] < refreshTime));
}

- (BOOL) isPostABeacon:(NSString*)postId
{
    return ([_activeBeacons objectForKey:postId] != nil);
}

- (void) createPostsArray:(id)responseObject
{
    // Reset beacons
    _activeBeacons = [NSMutableDictionary dictionaryWithCapacity:10];
    
    for (NSDictionary* post in responseObject)
    {
        ForeignTradePost* current = [[ForeignTradePost alloc] initWithDictionary:post];
        [self.activeBeacons setObject:current forKey:current.postId];
    }
}

- (void) retrieveBeaconsFromServer
{
    // make a get request
    AFHTTPClient* httpClient = [[AFClientManager sharedInstance] traderPog];
    NSString *userId = [NSString stringWithFormat:@"%d", [[Player getInstance] playerId]];
    [httpClient setDefaultHeader:@"user-id" value:userId];
    [httpClient getPath:@"posts/beacons"
             parameters:nil
                success:^(AFHTTPRequestOperation *operation, id responseObject){
                    NSLog(@"Retrieved: %@", responseObject);
                    [self createPostsArray:responseObject];
                    _lastUpdate = [NSDate date];
                    [self.delegate didCompleteHttpCallback:kBeaconMgr_ReceiveBeacons, TRUE];
                }
                failure:^(AFHTTPRequestOperation* operation, NSError* error){
                    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Server Failure"
                                                                      message:@"Unable to create retrieve beacons. Please try again later."
                                                                     delegate:nil
                                                            cancelButtonTitle:@"OK"
                                                            otherButtonTitles:nil];
                    
                    [message show];
                    [self.delegate didCompleteHttpCallback:kBeaconMgr_ReceiveBeacons, FALSE];
                }
     ];
    [httpClient setDefaultHeader:@"user_id" value:nil];
}

// this method performs linkage on variables that need to be resolved when
// all data in all managers (FlyerMgr, TradePostMgr, etc.) has been loaded
// specifically, it adds all the beacon posts as annotations in the game map, and it
// initializes the hasFlyer variable in each post;
- (void) addBeaconAnnotationsToMap:(MapControl*)map
{
    for(ForeignTradePost* cur in [_activeBeacons allValues])
    {
        [map addAnnotationForTradePost:cur isScan:NO];
        Flyer* flyerAtPost = [[FlyerMgr getInstance] flyerAtPostId:[cur postId]];
        if(flyerAtPost)
        {
            cur.flyerAtPost = flyerAtPost;
            [cur addArrivingFlyer:flyerAtPost];
        }
    }
}

- (void) clearForQuitGame
{
    [self.previewMap removeAllAnnotations];
    self.previewMap = nil;
}

#pragma mark - WheelDataSource
- (unsigned int) numItemsInWheel:(WheelControl *)wheel
{
    unsigned int num = [_activeBeacons count] + 1;
    return num;
}

static NSString* const kFbPictureUrl = @"https://graph.facebook.com/%@/picture";

- (WheelBubble*) wheel:(WheelControl *)wheel bubbleAtIndex:(unsigned int)index
{
    index = MIN(index, kBeaconNum - 1);

    WheelBubble* contentView = [wheel dequeueResuableBubble];
    if(nil == contentView)
    {
        CGRect contentRect = CGRectMake(5.0f, 5.0f, 30.0f, 30.0f);
        contentView = [[WheelBubble alloc] initWithFrame:contentRect];
    }
    contentView.imageView.backgroundColor = [GameColors bubbleBgColorWithAlpha:1.0f];
    UIColor* borderColor = [GameColors borderColorBeaconsWithAlpha:1.0f];
    [PogUIUtility setCircleForView:contentView.imageView
                   withBorderWidth:kBubbleBorderWidth
                       borderColor:borderColor
                    rasterizeScale:1.5f];

    if([_activeBeacons count] > index)
    {
        // request the FB picture for this beacon's owner
        ForeignTradePost* cur = [_activeBeacons.allValues objectAtIndex:index];
        if([cur fbId])
        {
            UrlImage* urlImage = [_cachedImages objectForKey:[cur fbId]];
            if(urlImage)
            {
                [contentView.imageView setImage:[urlImage image]];
            }
            else
            {
                NSString* pictureUrlString = [NSString stringWithFormat:kFbPictureUrl, [cur fbId]];
                urlImage = [[UrlImage alloc] initWithUrl:pictureUrlString
                                              completion:^(UrlImage* image){
                                                  if([image image])
                                                  {
                                                      [contentView.imageView setImage:[image image]];
                                                      [_cachedImages setObject:image forKey:[cur fbId]];
                                                  }
                                                  else
                                                  {
                                                      UIImage* image = [[ImageManager getInstance] getImage:@"bubble_beacon_g_001.png"];
                                                      [contentView.imageView setImage:image];
                                                  }
                                              }];
            }
        }
        else
        {
            // no fbid
            UIImage* image = [[ImageManager getInstance] getImage:@"bubble_beacon_g_001.png"];
            [contentView.imageView setImage:image];
        }
    }
    else
    {
        UIImage* image = [[ImageManager getInstance] getImage:@"bubble_beacon_fb.png"];
        [contentView.imageView setImage:image];
    }
    
    return contentView;
}

- (UIView*) wheel:(WheelControl*)wheel previewContentInitAtIndex:(unsigned int)index;
{
    MKMapView* result = nil;
    index = MIN(index, kBeaconNum - 1);
    if([_activeBeacons count] > index)
    {
        if(_previewMap)
        {
            result = [_previewMap view];
        }
        else
        {
            CGRect superFrame = wheel.previewView.bounds;
            result = [[MKMapView alloc] initWithFrame:superFrame];
            ForeignTradePost* initBeacon = [_activeBeacons.allValues objectAtIndex:index];
            _previewMap = [[MapControl alloc] initWithPreviewMapView:result
                                                    andCenter:[initBeacon coord]
                                                  atZoomLevel:kBeaconPreviewZoomLevel];
        }
    }
    else
    {
        // do nothing
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
    UIColor* result = [GameColors bubbleColorBeaconsWithAlpha:1.0f];
    return result;
}

- (UIColor*) previewButtonColorForWheel:(WheelControl *)wheel
{
    UIColor* result = [GameColors bubbleColorScanWithAlpha:1.0f];
    return result;
}

- (UIColor*) previewButtonBorderColorForWheel:(WheelControl *)wheel
{
    UIColor* result = [GameColors borderColorBeaconsWithAlpha:1.0f];
    return result;
}

#pragma mark - WheelProtocol
static const NSUInteger kPreviewLabelStrLenMax = 12;
- (void) wheel:(WheelControl*)wheel didMoveTo:(unsigned int)index
{
    index = MIN(index, kBeaconNum - 1);
    if([_activeBeacons count] > index)
    {
        ForeignTradePost* cur = [_activeBeacons.allValues objectAtIndex:index];
        [_previewMap centerOn:[cur coord] animated:YES];
        [wheel.previewImageView setImage:nil];
        [wheel.previewImageView setHidden:YES];
        
        NSString* fbName = nil;
        if([cur fbId])
        {
            fbName = [[Player getInstance] getFacebookNameByFbid:[cur fbId]];
        }
        if(fbName)
        {
            fbName = [PogUIUtility stringFromString:fbName looselyCapLength:kPreviewLabelStrLenMax withSeparator:@" "];
            [wheel.previewLabel setText:fbName];
        }
        else
        {
            [wheel.previewLabel setText:@"Friend Pog"];
        }
        [wheel.previewLabel setNumberOfLines:1];
        [wheel.previewLabel setFont:[UIFont fontWithName:@"Marker Felt" size:19.0f]];
        [wheel.previewLabel setAdjustsFontSizeToFitWidth:YES];
    }
    else
    {
        if([[Player getInstance] isFacebookConnected])
        {
            [wheel.previewLabel setText:@"Invite Friends!"];
        }
        else
        {
            [wheel.previewLabel setText:@"Connect!"];
        }
        // empty flyer slot
        [wheel.previewLabel setNumberOfLines:1];
        [wheel.previewLabel setFont:[UIFont fontWithName:@"Marker Felt" size:19.0f]];
        [wheel.previewLabel setAdjustsFontSizeToFitWidth:YES];
        UIImage* bgImage = [[ImageManager getInstance] getImage:@"bubble_beacon_fb.png" fallbackNamed:@"bubble_beacon_fb.png"];
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
    index = MIN(index, kBeaconNum - 1);
    if([_activeBeacons count] > index)
    {
        index = MIN(index, [_activeBeacons count]-1);
        ForeignTradePost* cur = [_activeBeacons.allValues objectAtIndex:index];
        [wheel.superMap defaultZoomCenterOn:[cur coord] animated:YES];
    }
    else
    {        
        if([[Player getInstance] isFacebookConnected])
        {
            NSLog(@"Invite Friends!");
            [[Player getInstance] updateFacebookFeed:@"I'm playing Traderpog! Won't you come join me?" useTimer:FALSE];
            UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Invite posted to your Facebook wall"
                                                              message:@"When your friends play TraderPog, they will appear on this wheel. Watch this space."
                                                             delegate:nil
                                                    cancelButtonTitle:@"OK"
                                                    otherButtonTitles:nil];
            
            [message show];
        }
        else
        {
            NSLog(@"Connecting to Facebook account!");
            [[Player getInstance] authorizeFacebook];
        }
    }
}

- (void) wheel:(WheelControl *)wheel didPressCloseOnIndex:(unsigned int)index
{
    // do nothing
}

- (void) wheel:(WheelControl*)wheel willShowAtIndex:(unsigned int)index
{
    // refresh at this index
    [self wheel:wheel didMoveTo:index];

    // refresh preview map
    [_previewMap removeAllAnnotations];
    [self addBeaconAnnotationsToMap:_previewMap];
}

- (void) wheel:(WheelControl*)wheel willHideAtIndex:(unsigned int)index
{
    // do nothing
}

#pragma mark - Singleton
static BeaconMgr* singleton = nil;
+ (BeaconMgr*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
            if (!singleton)
            {
                singleton = [[BeaconMgr alloc] init];
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
