//
//  TradeItem.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/15/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TradeItemType.h"

@interface TradeItem : NSObject<NSCoding>
{
    __weak TradeItemType* _itemType;
    unsigned int    _price;
    float           _restockRate;
}
@property (nonatomic,weak) TradeItemType* itemType;
@property (nonatomic) unsigned int price;
@property (nonatomic) float restockRate;

- (id) initWithItemType:(TradeItemType*)itemType price:(unsigned int)price restockRate:(float)restockRate;

@end
