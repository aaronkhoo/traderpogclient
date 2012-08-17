//
//  PlayerPostCallout.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/17/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "MapProtocols.h"

@class TradePost;
@interface PlayerPostCallout : NSObject<MKAnnotation,MapAnnotationProtocol>
{
    CLLocationCoordinate2D _coord;
    __weak TradePost* _tradePost;
}
@property (nonatomic,weak) TradePost* tradePost;
@property (nonatomic,weak) MKAnnotationView* parentAnnotationView;
- (id) initWithTradePost:(TradePost*)tradePost;

@end
