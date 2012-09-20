//
//  Leaderboard.h
//  traderpog
//
//  Created by Aaron Khoo on 9/18/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LeaderboardRow.h"

@interface Leaderboard : NSObject<NSCoding>
{
    NSMutableArray* _lbRows;
    NSString* _lbName;
    NSDate* _weekOf;
}
@property (nonatomic,strong) NSMutableArray* lbRows;
@property (nonatomic,strong) NSString* lbName;
@property (nonatomic,strong) NSDate* weekOf;

- (id) initBoard:(NSString*)name, NSDate* current_date;
- (void) insertNewRow:(LeaderboardRow*)current_row;
- (void) clearLeaderboard;
- (void) sortLeaderboard;

@end
