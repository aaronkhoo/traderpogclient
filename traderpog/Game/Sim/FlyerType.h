//
//  FlyerType.h
//  traderpog
//
//  Created by Aaron Khoo on 7/25/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FlyerType : NSObject<NSCoding>
{
    // internal
    NSString* _createdVersion;
    
    // Flyer type values
    NSString* _flyerId;
    NSString* _name;
    NSString* _desc;
    NSInteger _price;
    NSInteger _capacity;
    NSInteger _loadtime;
    NSInteger _speed;
    NSInteger _multiplier;
    NSInteger _stormresist;
    NSInteger _tier;
    NSString* _topimg;
    NSString* _sideimg;
    NSInteger _loadTime;
}
@property (nonatomic,strong) NSString* flyerId;
@property (nonatomic,strong) NSString* name;
@property (nonatomic,strong) NSString* desc;
@property (nonatomic) NSInteger tier;
@property (nonatomic) NSInteger speed;
@property (nonatomic,strong) NSString* topimg;
@property (nonatomic,strong) NSString* sideimg;
@property (nonatomic) NSInteger loadtime;

- (id) initWithDictionary:(NSDictionary*)dict;

// returns a type-name that can be used to lookup info from the flyerlab registry
- (NSString*) getNameForFlyerLab;
@end
