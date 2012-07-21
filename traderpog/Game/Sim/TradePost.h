//
//  TradePost.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class TradeItemType;
@class TradePostAnnotation;
@interface TradePost : NSObject<NSCoding>
{
    NSString*   _postId;
    CLLocationCoordinate2D _coord;
    NSString*   _itemId;
    BOOL        _isHomebase;
    
    // transient variables (not saved; reconstructed after load)
    __weak TradePostAnnotation* _annotation;
}
@property (nonatomic) NSString* postId;
@property (nonatomic) CLLocationCoordinate2D coord;
@property (nonatomic) NSString* itemId;
@property (nonatomic) BOOL isHomebase;
@property (nonatomic,weak) TradePostAnnotation* annotation;
- (id) initWithPostId:(NSString*)postId
           coordinate:(CLLocationCoordinate2D)coordinate 
                 itemType:(TradeItemType *)itemType;
@end
