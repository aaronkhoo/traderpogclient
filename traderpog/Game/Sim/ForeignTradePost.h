//
//  ForeignTradePost.h
//  traderpog
//
//  Created by Aaron Khoo on 8/31/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PlayerTradePost.h"

@interface ForeignTradePost : PlayerTradePost
{
    NSString*   _userId;
    NSString*   _fbId;
}
@property (nonatomic,readonly) NSString* fbId;

@end
