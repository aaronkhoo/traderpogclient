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
    NSString* _fbname;
    NSString* _fbid;
    NSInteger _lbValue;
    BOOL _member;
}
@property (nonatomic) NSString* fbname;
@property (nonatomic) NSString* fbid;
@property (nonatomic) NSInteger lbValue;
@property (nonatomic) BOOL member;

- (id) initWithData:(NSString*)current_fbname
       current_fbid:(NSString*)current_fbid
      current_value:(NSInteger)current_value
     current_member:(BOOL)current_member;

@end
