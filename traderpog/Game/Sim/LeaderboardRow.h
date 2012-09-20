//
//  LeaderboardRow.h
//  traderpog
//
//  Created by Aaron Khoo on 9/19/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LeaderboardRow : NSObject<NSCoding>
{
    NSString* _fbid;
    NSInteger _lbValue;
}
@property (nonatomic) NSString* fbid;
@property (nonatomic) NSInteger lbValue;

- (id) initWithFbidAndValue:(NSString*)current_fbid current_value:(NSInteger)current_value;

@end
