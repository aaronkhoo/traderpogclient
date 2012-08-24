//
//  WorldState.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Flyer;
@interface WorldState : NSObject<NSCoding>
{
    NSMutableDictionary* _flyersInventory;  // key: flyerId; value: NSDictionary;
}
@property (nonatomic,strong) NSMutableDictionary* flyersInventory;

- (void) refreshDataFromGame;

- (void) setDataIntoFlyer:(Flyer*)flyer;

+ (NSString*) filepath;

@end
