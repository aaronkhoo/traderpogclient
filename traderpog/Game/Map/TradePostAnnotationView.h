//
//  TradePostAnnotationView.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/15/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MapProtocols.h"

extern NSString* const kTradePostAnnotationViewReuseId;
@class TradePostAnnotation;
@interface TradePostAnnotationView : MKAnnotationView<MapAnnotationViewProtocol>

- (id) initWithAnnotation:(TradePostAnnotation*)annotation;
@end
