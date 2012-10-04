//
//  SingleLeaderboard.m
//  traderpog
//
//  Created by Aaron Khoo on 10/3/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "UINavigationController+Pog.h"
#import "Leaderboard.h"
#import "LeaderboardMgr.h"
#import "LeaderboardRowCell.h"
#import "Player.h"
#import "SingleLeaderboard.h"

static NSString* const kKeyIndex = @"index";
static NSString* const kKeyName = @"name";
static NSString* const kKeyValue = @"value";

@implementation SingleLeaderboard
@synthesize leaderboardName;

- (id)initWithNibNameAndIndex:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil index:(NSUInteger)index
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {         
        Leaderboard* current_lb = [[[LeaderboardMgr getInstance] leaderboards] objectAtIndex:index];
        _currentName = current_lb.lbName;
         
        // Set up conversion of RFC 3339 time format
        NSDateFormatter *dateformat = [[NSDateFormatter alloc] init];
        [dateformat setDateStyle:NSDateFormatterMediumStyle];
        [dateformat setTimeStyle:NSDateFormatterNoStyle];
        _currentWeek = [dateformat stringFromDate:[current_lb week_of]];
        
        _currentRows = [[NSMutableArray alloc] initWithCapacity:11];
        BOOL playerFound = FALSE;
        NSUInteger index = 1;
        NSUInteger count = 0;
        for (LeaderboardRow* current_row in [current_lb lbRows])
        {
            BOOL isCurrentPlayer = ([[current_row fbname] compare:[[Player getInstance] fbname]] == NSOrderedSame);
            
            // Fewer than 10 so far || current row is the player
            if (count < 10 || isCurrentPlayer)
            {
                NSMutableDictionary* rowDict = [[NSMutableDictionary alloc] initWithCapacity:4];
                [rowDict setObject:[NSNumber numberWithUnsignedInteger:index] forKey:kKeyIndex];
                [rowDict setObject:[current_row fbname] forKey:kKeyName];
                [rowDict setObject:[NSNumber numberWithUnsignedInteger:[current_row lbValue]] forKey:kKeyValue];
                [_currentRows addObject:rowDict];
                
                playerFound = isCurrentPlayer;
                count++;
            }

            if (count >= 10 && playerFound)
            {
                // Found at least 10 players and one of them is the player
                break;
            }

            index++;
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    leaderboardName.text = _currentName;
}

- (IBAction)didPressClose:(id)sender
{
    [self.navigationController popToRightViewControllerAnimated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_currentRows count] + 2;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"LeaderboardRowCell";
    
    LeaderboardRowCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {        
        // Load the top-level objects from the custom cell XIB.
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"LeaderboardRowCell" owner:self options:nil];
        // Grab a pointer to the first object (presumably the custom cell, as that's all the XIB should contain).
        cell = [topLevelObjects objectAtIndex:0];
    }
    
    if (indexPath.row == 0)
    {
        cell.leftLabel.text = @"Week of";
        cell.middleLabel.text = @"";
        cell.rightLabel.text = _currentWeek;
    }
    else if (indexPath.row == 1)
    {
        cell.leftLabel.text = @"";
        cell.middleLabel.text = @"";
        cell.rightLabel.text = @"";
    }
    else
    {
        NSUInteger index = indexPath.row - 2;
        NSDictionary* currentRow = [_currentRows objectAtIndex:index];
        
        cell.leftLabel.text = [NSString stringWithFormat:@"#%d", [[currentRow objectForKey:kKeyIndex] unsignedIntegerValue]];
        cell.middleLabel.text = [NSString stringWithFormat:@"%@", [currentRow objectForKey:kKeyName]];
        cell.rightLabel.text = [NSString stringWithFormat:@"%d", [[currentRow objectForKey:kKeyValue] unsignedIntegerValue]];
    }
    
    return cell;
}

@end
