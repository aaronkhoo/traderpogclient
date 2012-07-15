//
//  TradePost.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface TradePost : NSObject<NSCoding>
{
    NSString*   _postId;
    CLLocationCoordinate2D _coord;
    NSString*   _itemId;
    BOOL        _isHomebase;
}
@property (nonatomic) NSString* postId;
@property (nonatomic) CLLocationCoordinate2D coord;
@property (nonatomic) NSString* itemId;
@property (nonatomic) BOOL isHomebase;
- (id) initWithPostId:(NSString*)postId
           coordinate:(CLLocationCoordinate2D)coordinate 
                 item:(NSString *)itemId;
@end
