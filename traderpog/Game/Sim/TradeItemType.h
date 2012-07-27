//
//  TradeItemType.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/15/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TradeItemType : NSObject
{
    NSString* _itemId;
    NSString* _name;
    NSString* _desc;
    NSInteger _price;
    NSInteger _supplymax;
    NSInteger _supplyrate;
    NSInteger _multiplier;
    NSInteger _tier;
}
@property (nonatomic,strong) NSString* itemId;
@property (nonatomic,strong) NSString* name;
@property (nonatomic,strong) NSString* desc;
@property (nonatomic) NSInteger price;
@property (nonatomic) NSInteger supplymax;
@property (nonatomic) NSInteger supplyrate;
@property (nonatomic) NSInteger multiplier;
@property (nonatomic) NSInteger tier;

- (id) initWithDictionary:(NSDictionary*)dict;

@end
