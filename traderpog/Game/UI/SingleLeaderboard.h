//
//  SingleLeaderboard.h
//  traderpog
//
//  Created by Aaron Khoo on 10/3/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CircleButton.h"

@interface SingleLeaderboard : UIViewController<UITableViewDelegate, UITableViewDataSource>
{
    NSString* _currentName;
    NSString* _currentWeek;
    NSMutableArray* _currentRows;
    UIImage* _lbImage;
    NSUInteger _playerIndex;
}
@property (weak, nonatomic) IBOutlet UILabel* leaderboardName;
@property (weak, nonatomic) IBOutlet UITableView* leaderboardTable;
@property (weak, nonatomic) IBOutlet CircleButton *closeCircle;
@property (weak, nonatomic) IBOutlet UIImageView *leaderboardImage;

- (id)initWithNibNameAndIndex:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil index:(NSUInteger)index;

@end
