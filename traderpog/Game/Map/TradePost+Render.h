//
//  TradePost+Render.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 9/11/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "TradePost.h"

@class TradePostAnnotationView;
@class ItemBuyView;
@interface TradePost (Render)
- (void) refreshRenderForAnnotationView:(TradePostAnnotationView*)annotationView;
- (void) refreshRenderForItemBuyView:(ItemBuyView*)buyView;
@end
