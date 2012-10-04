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
#import "SingleLeaderboard.h"

@implementation LeaderboardsScreen
@synthesize spinner;
@synthesize bucksButton;
@synthesize totalButton;
@synthesize furthestButton;
@synthesize postsVisitedButton;

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
        [spinner stopAnimating];
        spinner.hidden = TRUE;
        [self enableButtons];
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

- (IBAction)didPressBucks:(id)sender
{
    SingleLeaderboard* leaderboard = [[SingleLeaderboard alloc] initWithNibNameAndIndex:@"SingleLeaderboard" bundle:nil index:0];
    [self.navigationController pushFromRightViewController:leaderboard animated:YES];
}

- (IBAction)didPressTotalDistance:(id)sender
{
    SingleLeaderboard* leaderboard = [[SingleLeaderboard alloc] initWithNibNameAndIndex:@"SingleLeaderboard" bundle:nil index:1];
    [self.navigationController pushFromRightViewController:leaderboard animated:YES];
}

- (IBAction)didPressFurthestDistance:(id)sender
{
    SingleLeaderboard* leaderboard = [[SingleLeaderboard alloc] initWithNibNameAndIndex:@"SingleLeaderboard" bundle:nil index:2];
    [self.navigationController pushFromRightViewController:leaderboard animated:YES];
}

- (IBAction)didPressPostsVisited:(id)sender
{
    SingleLeaderboard* leaderboard = [[SingleLeaderboard alloc] initWithNibNameAndIndex:@"SingleLeaderboard" bundle:nil index:3];
    [self.navigationController pushFromRightViewController:leaderboard animated:YES];
}

- (void)updateLeaderboardUI
{
    [spinner stopAnimating];
    spinner.hidden = TRUE;
    
    [self enableButtons];
}

- (void) enableButtons
{
    self.bucksButton.enabled = TRUE;
    self.totalButton.enabled = TRUE;
    self.furthestButton.enabled = TRUE;
    self.postsVisitedButton.enabled = TRUE;
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
        //leaderboard.text = @"Leaderboards current unavailable";
    }
}

@end
