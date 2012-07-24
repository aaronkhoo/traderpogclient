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

static NSString* const kKeyPostId = @"id";
static NSString* const kKeyUserId = @"user_id";
static NSString* const kKeyLong = @"longitude";
static NSString* const kKeyLat = @"latitude";
static NSString* const kKeyItemId = @"item_info_id";
static NSString* const kKeyImgPath= @"img";
static NSString* const kKeySupplyRateLevel = @"supplymaxlevel";
static NSString* const kKeySupplyMaxLevel = @"supplyratelevel";
static NSString* const kKeyHomebaseBool = @"homebaseBool";

static NSString* const kPlayer_CreateNewPost = @"CreateNewPost";

@implementation TradePost
@synthesize postId = _postId;
@synthesize itemId = _itemId;
@synthesize isHomebase = _isHomebase;
@synthesize annotation = _annotation;
@synthesize delegate = _delegate;

- (id) initWithPostId:(NSString*)postId
           coordinate:(CLLocationCoordinate2D)coordinate 
                 itemType:(TradeItemType *)itemType
{
    self = [super init];
    if(self)
    {
        _postId = postId;
        _coord = coordinate;
        _itemId = [itemType itemId];
        _isHomebase = NO;
        _annotation = nil;
    }
    return self;
}

- (id) initWithCoordinates:(CLLocationCoordinate2D)coordinate 
                           itemType:(TradeItemType *)itemType
{
    self = [super init];
    if(self)
    {
        _coord = coordinate;
        _itemId = [itemType itemId];
        _isHomebase = NO;
        _annotation = nil;
    }
    return self;
}

- (void) createNewPostOnServer
{
    // post parameters
    NSString *userId = [NSString stringWithFormat:@"%d", [[Player getInstance] id]];
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
                     _postId = [responseObject valueForKeyPath:kKeyPostId];
                     _imgPath = [responseObject valueForKeyPath:kKeyImgPath];
                     _supplyMaxLevel = [[responseObject valueForKeyPath:kKeySupplyMaxLevel] integerValue];
                     _supplyRateLevel = [[responseObject valueForKeyPath:kKeySupplyRateLevel] integerValue];
                     [self.delegate didCompleteHttpCallback:kPlayer_CreateNewPost, TRUE];
                 }
                 failure:^(AFHTTPRequestOperation* operation, NSError* error){
                     UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Server Failure"
                                                                       message:@"Unable to create post. Please try again later."
                                                                      delegate:nil
                                                             cancelButtonTitle:@"OK"
                                                             otherButtonTitles:nil];
                     
                     [message show];
                     [self.delegate didCompleteHttpCallback:kPlayer_CreateNewPost, FALSE];
                 }
     ];
}

#pragma mark - getters/setters
- (CLLocationCoordinate2D) coord
{
    return _coord;
}

- (void) setCoord:(CLLocationCoordinate2D)coord
{
    _coord = coord;
    if([self annotation])
    {
        [self.annotation setCoordinate:coord];
    }
}

@end
