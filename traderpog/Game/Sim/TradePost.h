//
//  TradePost.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "HttpCallbackDelegate.h"

static NSString* const kTradePost_CreateNewPost = @"CreateNewPost";

@class TradeItemType;
@class TradePostAnnotation;
@interface TradePost : NSObject
{
    NSString*   _postId;
    CLLocationCoordinate2D _coord;
    NSString*   _itemId;
    NSString*   _imgPath;
    NSInteger   _supplyMaxLevel;
    NSInteger   _supplyRateLevel;
    
    // transient variables (not saved; reconstructed after load)
    __weak TradePostAnnotation* _annotation;
    
    // Delegate for callbacks to inform interested parties of completion
    __weak NSObject<HttpCallbackDelegate>* _delegate;
}
@property (nonatomic) NSString* postId;
@property (nonatomic) CLLocationCoordinate2D coord;
@property (nonatomic) NSString* itemId;
@property (nonatomic,weak) TradePostAnnotation* annotation;
@property (nonatomic,weak) NSObject<HttpCallbackDelegate>* delegate;

- (id) initWithPostId:(NSString*)postId
           coordinate:(CLLocationCoordinate2D)coordinate 
                 itemType:(TradeItemType *)itemType;
- (id) initWithCoordinates:(CLLocationCoordinate2D)coordinate 
                           itemType:(TradeItemType *)itemType;
- (void) createNewPostOnServer;
- (id) initWithDictionary:(NSDictionary*)dict;
@end
