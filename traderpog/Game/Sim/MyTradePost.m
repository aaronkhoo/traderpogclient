//
//  MyTradePost.m
//  traderpog
//
//  Created by Aaron Khoo on 8/31/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "AFClientManager.h"
#import "ImageManager.h"
#import "MetricLogger.h"
#import "MyTradePost.h"
#import "Player.h"
#import "PogUIUtility.h"
#import "TradeItemType.h"
#import "TradePostMgr.h"
#import "TradePostAnnotationView.h"
#import "TradePost+Render.h"
#import "Flyer.h"

@implementation MyTradePost
@synthesize preFlyerLab = _preFlyerLab;
@synthesize lastUnloadedItemId = _lastUnloadedItemId;

#pragma mark - public functions
- (id) initWithDictionary:(NSDictionary*)dict
{
    self = [super initWithDictionary:dict];
    if (self)
    {
        _supplyLevel = [[dict valueForKeyPath:kKeyTradeSupply] integerValue];
        _preFlyerLab = NO;
        
        // transients
        _lastUnloadedItemId = nil;
    }
    return self;
}

// call this to create player posts
- (id) initWithCoordinates:(CLLocationCoordinate2D)coordinate
                  itemType:(TradeItemType *)itemType
{
    self = [super init];
    if(self)
    {
        _coord = coordinate;
        _itemId = [itemType itemId];
        _beacontime = nil;
        _preFlyerLab = NO;
        
        // transients
        _lastUnloadedItemId = nil;
    }
    return self;
}

#pragma mark - server calls

- (void) createNewPostOnServer
{
    // post parameters
    NSString *userId = [NSString stringWithFormat:@"%d", [[Player getInstance] playerId]];
    NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                userId, kKeyTradeUserId,
                                [NSNumber numberWithDouble:_coord.longitude], kKeyTradeLong,
                                [NSNumber numberWithDouble:_coord.latitude], kKeyTradeLat,
                                _itemId, kKeyTradeItemId,
                                nil];
    
    // make a post request
    AFHTTPClient* httpClient = [[AFClientManager sharedInstance] traderPog];
    [httpClient postPath:@"posts.json"
              parameters:parameters
                 success:^(AFHTTPRequestOperation *operation, id responseObject){
                     _postId = [NSString stringWithFormat:@"%d", [[responseObject valueForKeyPath:kKeyTradePostId] integerValue]];
                     _imgPath = [responseObject valueForKeyPath:kKeyTradeImgPath];
                     _supplyMaxLevel = [[responseObject valueForKeyPath:kKeyTradeSupplyMaxLevel] integerValue];
                     _supplyRateLevel = [[responseObject valueForKeyPath:kKeyTradeSupplyRateLevel] integerValue];
                     [self.delegate didCompleteHttpCallback:kTradePost_CreateNewPost, TRUE];
                 }
                 failure:^(AFHTTPRequestOperation* operation, NSError* error){
                     UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Server Failure"
                                                                       message:@"Unable to create post. Please try again later."
                                                                      delegate:nil
                                                             cancelButtonTitle:@"OK"
                                                             otherButtonTitles:nil];
                     
                     [message show];
                     [self.delegate didCompleteHttpCallback:kTradePost_CreateNewPost, FALSE];
                 }
     ];
}

- (void) updatePost:(NSDictionary*)parameters
{
    // make a post request
    AFHTTPClient* httpClient = [[AFClientManager sharedInstance] traderPog];
    NSString *postUrl = [NSString stringWithFormat:@"posts/%@", _postId];
    [httpClient putPath:postUrl
             parameters:parameters
                success:^(AFHTTPRequestOperation *operation, id responseObject){
                    NSLog(@"Post data updated");
                    // Update beacontime
                    id obj = [responseObject valueForKeyPath:kKeyTradeBeacontime];
                    if ((NSNull *)obj != [NSNull null])
                    {
                        NSString* utcdate = [NSString stringWithFormat:@"%@", obj];
                        if (![utcdate isEqualToString:@"<null>"])
                        {
                            _beacontime = [PogUIUtility convertUtcToNSDate:utcdate];
                        }
                    }
                }
                failure:^(AFHTTPRequestOperation* operation, NSError* error){
                    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Server Failure"
                                                                      message:@"Unable to update post. Please try again later."
                                                                     delegate:nil
                                                            cancelButtonTitle:@"OK"
                                                            otherButtonTitles:nil];
                    
                    [message show];
                }
     ];
}

- (void) setBeacon
{
    if ([[TradePostMgr getInstance] isBeaconActive])
    {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Beacon exists"
                                                          message:@"Only a single beacon can be active at a time"
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
        
        [message show];
    }
    else
    {
        NSDateFormatter *format = [[NSDateFormatter alloc] init];
        [format setDateFormat:@"MMM dd, yyyy HH:mm"];
        NSDate *now = [[NSDate alloc] init];
        NSString *dateString = [format stringFromDate:now];
        NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                    dateString, kKeyTradeBeacontime,
                                    nil];
        [self updatePost:parameters];
        
        // Beacons don't have "slots". Put 0 as a placeholder.
        [MetricLogger logCreateObject:@"Beacon" slot:0 member:[[Player getInstance] isMember]];
    }
}

- (bool) beaconActive
{
    return (_beacontime && ([_beacontime timeIntervalSinceNow] > 0));
}
/*
- (unsigned int) getMyTradePostState
{
    unsigned int state = kMyTradePostState_Idle;
    
    if([self flyerAtPost])
    {
        Flyer* flyer = [self flyerAtPost];
        if(kFlyerStateWaitingToUnload == [flyer state])
        {
            state = kMyTradePostState_FlyerWaitingToUnload;
        }
        else if(kFlyerStateUnloading == [flyer state])
        {
            state = kMyTradePostState_FlyerUnloading;
        }
        else if([self preFlyerLab])
        {
            state = kMyTradePostState_PreFlyerLab;
        }
        else
        {
            state = kMyTradePostState_FlyerIdle;
        }
    }
    
    return state;
}
*/
#pragma mark - MapAnnotationProtocol
- (MKAnnotationView*) annotationViewInMap:(MKMapView *)mapView
{
    TradePostAnnotationView* annotationView = [super getAnnotationViewInstance:mapView];
    
    // own post is always enabled
    annotationView.enabled = YES;
    [self refreshRenderForAnnotationView:annotationView];
    
    return annotationView;
}

@end
