//
//  LeaderboardsScreen.m
//  traderpog
//
//  Created by Aaron Khoo on 9/24/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "UINavigationController+Pog.h"
#import "Leaderboard.h"
#import "LeaderboardMgr.h"
#import "LeaderboardRow.h"
#import "LeaderboardsScreen.h"
#import "Player.h"

@implementation LeaderboardsScreen
@synthesize spinner;
@synthesize leaderboard;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[LeaderboardMgr getInstance] setDelegate:self];
    
    spinner.hidden = FALSE;
    
    if ([[LeaderboardMgr getInstance] needsRefresh])
    {
        [spinner startAnimating];
        [[LeaderboardMgr getInstance] retrieveLeaderboardFromServer];
    }
    else
    {
        [self updateLeaderboardUI];
    }
}

- (void)viewDidUnload
{
    [[LeaderboardMgr getInstance] setDelegate:nil];
}

- (IBAction)didPressClose:(id)sender
{
    [self.navigationController popToRightViewControllerAnimated:YES];
}

- (void)updateLeaderboardUI
{
    [spinner stopAnimating];
    spinner.hidden = TRUE;
    
    leaderboard.numberOfLines = 0;
    
    // Just display one leaderboard for now
    Leaderboard* current_lb = [[[LeaderboardMgr getInstance] leaderboards] objectAtIndex:0];
    
    // Set up conversion of RFC 3339 time format
    NSDateFormatter *dateformat = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    
    [dateformat setLocale:enUSPOSIXLocale];
    [dateformat setDateFormat:@"yyyy'-'MM'-'dd' GMT"];
    [dateformat setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    // Convert the RFC 3339 date time string to an NSDate.
    NSString* week_of_text = [dateformat stringFromDate:[current_lb week_of]];
    
    NSString* label_text = [NSString stringWithFormat:@"%@\rWeek of: %@\r",
                            [current_lb lbName],
                            week_of_text];
    
    NSUInteger index = 1;
    for (LeaderboardRow* current_row in [current_lb lbRows])
    {
        NSString* row_in_text = [NSString stringWithFormat:@"%d. %@ %d\r", index, [current_row fbname], [current_row lbValue]];
        label_text = [label_text stringByAppendingString:row_in_text];
        index++;
    }
    leaderboard.text = label_text;
}

#pragma mark - HttpCallbackDelegate
- (void) didCompleteHttpCallback:(NSString*)callName, BOOL success
{
    if (success)
    {
        [self updateLeaderboardUI];
    }
    else
    {
        [spinner stopAnimating];
        spinner.hidden = TRUE;
        leaderboard.text = @"Leaderboards current unavailable";
    }
}

@end
