//
//  TradePost.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "AFClientManager.h"
#import "Player.h"
#import "TradePost.h"
#import "TradeItemType.h"
#import "TradePostAnnotation.h"
#import "TradePostAnnotationView.h"

static NSString* const kKeyPostId = @"id";
static NSString* const kKeyUserId = @"user_id";
static NSString* const kKeyLong = @"longitude";
static NSString* const kKeyLat = @"latitude";
static NSString* const kKeyItemId = @"item_info_id";
static NSString* const kKeyImgPath= @"img";
static NSString* const kKeySupplyRateLevel = @"supplymaxlevel";
static NSString* const kKeySupplyMaxLevel = @"supplyratelevel";

@implementation TradePost
@synthesize postId = _postId;
@synthesize itemId = _itemId;
@synthesize annotation = _annotation;
@synthesize supplyLevel = _supplyLevel;
@synthesize isOwnPost = _isOwnPost;
@synthesize isNPCPost = _isNPCPost;
@synthesize delegate = _delegate;

// call this to create NPC posts
- (id) initWithPostId:(NSString*)postId
           coordinate:(CLLocationCoordinate2D)coordinate 
                 itemType:(TradeItemType *)itemType
          supplyLevel:(unsigned int)supply
{
    self = [super init];
    if(self)
    {
        _postId = postId;
        _coord = coordinate;
        _itemId = [itemType itemId];
        _annotation = nil;
        _supplyLevel = MIN([itemType supplymax],supply);
        
        // NPC post
        _isOwnPost = NO;
        _isNPCPost = YES;
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
        _annotation = nil;
        
        // client can only create tradePosts for current player;
        _isOwnPost = YES;
        _isNPCPost = NO;
    }
    return self;
}

- (id) initWithDictionary:(NSDictionary*)dict
{
    self = [super init];
    if(self)
    {
        _postId = [NSString stringWithFormat:@"%d", [[dict valueForKeyPath:@"id"] integerValue]];
        _coord.latitude = [[dict valueForKeyPath:@"latitude"] doubleValue];
        _coord.longitude = [[dict valueForKeyPath:@"longitude"] doubleValue];
        _itemId = [dict valueForKeyPath:@"item_info_id"];
        _imgPath = [dict valueForKeyPath:@"img"];
        _supplyMaxLevel =[[dict valueForKeyPath:@"supplymaxlevel"] integerValue];
        _supplyRateLevel =[[dict valueForKeyPath:@"supplyratelevel"] integerValue];
        
        _isNPCPost = NO;
        
        // HACK
        // TODO: get this from server
        _isOwnPost = YES;
        // HACK
        
        // transient variables
        _supplyLevel = _supplyMaxLevel;
        _annotation = nil;
    }
    return self;
}

- (void) createNewPostOnServer
{
    // post parameters
    NSString *userId = [NSString stringWithFormat:@"%d", [[Player getInstance] playerId]];
    NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                userId, kKeyUserId,
                                [NSNumber numberWithDouble:_coord.longitude], kKeyLong, 
                                [NSNumber numberWithDouble:_coord.latitude], kKeyLat, 
                                _itemId, kKeyItemId,
                                nil];
    
    // make a post request
    AFHTTPClient* httpClient = [[AFClientManager sharedInstance] traderPog];
    [httpClient postPath:@"posts.json" 
              parameters:parameters
                 success:^(AFHTTPRequestOperation *operation, id responseObject){                     
                     _postId = [NSString stringWithFormat:@"%d", [[responseObject valueForKeyPath:kKeyPostId] integerValue]];
                     _imgPath = [responseObject valueForKeyPath:kKeyImgPath];
                     _supplyMaxLevel = [[responseObject valueForKeyPath:kKeySupplyMaxLevel] integerValue];
                     _supplyRateLevel = [[responseObject valueForKeyPath:kKeySupplyRateLevel] integerValue];
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


#pragma mark - trade
- (void) deductNumItems:(unsigned int)num
{
    unsigned int numToSub = MIN([self supplyLevel], num);
    self.supplyLevel -= numToSub;
}

#pragma mark - getters/setters
- (CLLocationCoordinate2D) coord
{
    return _coord;
}

- (void) setCoord:(CLLocationCoordinate2D)coord
{
    _coord = coord;
}


#pragma mark - MKAnnotation delegate
- (CLLocationCoordinate2D) coordinate
{
    return [self coord];
}

- (void) setCoordinate:(CLLocationCoordinate2D)newCoordinate
{
    self.coord = newCoordinate;
}

#pragma mark - MapAnnotationProtocol
- (MKAnnotationView*) annotationViewInMap:(MKMapView *)mapView
{
    MKAnnotationView* annotationView = (TradePostAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:kTradePostAnnotationViewReuseId];
    if(annotationView)
    {
        annotationView.annotation = self;
    }
    else
    {
        annotationView = [[TradePostAnnotationView alloc] initWithAnnotation:self];
    }
    
    return annotationView;
}

@end
