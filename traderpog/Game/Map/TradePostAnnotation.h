//
//  TradePostAnnotation.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/15/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MKAnnotation.h>
#import "MapProtocols.h"

@class TradePost;
@interface TradePostAnnotation : NSObject<MKAnnotation, MapAnnotationProtocol>
{
    TradePost* _tradePost;
}
@property (nonatomic,readonly) TradePost* tradePost;
- (id) initWithTradePost:(TradePost*)tradePost;
@end
