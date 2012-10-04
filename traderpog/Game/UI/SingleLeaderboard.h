//
//  SingleLeaderboard.h
//  traderpog
//
//  Created by Aaron Khoo on 10/3/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SingleLeaderboard : UIViewController<UITableViewDelegate, UITableViewDataSource>
{
    NSString* _currentName;
    NSString* _currentWeek;
    NSMutableArray* _currentRows;
}
@property (weak, nonatomic) IBOutlet UILabel *leaderboardName;

- (id)initWithNibNameAndIndex:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil index:(NSUInteger)index;

@end
