//
//  TradeManager.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/11/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Flyer;
@class TradePost;
@interface TradeManager : NSObject

- (void) flyer:(Flyer*)flyer buyFromPost:(TradePost*)post numItems:(unsigned int)numItems;

// singleton
+(TradeManager*) getInstance;
+(void) destroyInstance;

@end
