//
//  FlyerType.h
//  traderpog
//
//  Created by Aaron Khoo on 7/25/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FlyerType : NSObject
{
    NSString* _flyerId;
    NSString* _name;
    NSString* _desc;
    NSInteger _price;
    NSInteger _capacity;
    NSInteger _speed;
    NSInteger _multiplier;
    NSInteger _stormresist;
    NSInteger _tier;
}
@property (nonatomic,strong) NSString* flyerId;
@property (nonatomic,strong) NSString* name;
@property (nonatomic,strong) NSString* desc;
@property (nonatomic) NSInteger tier;

- (id) initWithDictionary:(NSDictionary*)dict;

@end
