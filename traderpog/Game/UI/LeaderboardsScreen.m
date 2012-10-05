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

static CGFloat const kRowHeight = 45.0;
static NSUInteger const kSkippedRows = 2;

@implementation LeaderboardsScreen
@synthesize spinner;
@synthesize lbtable;
@synthesize errorLabel;

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
    
    UIColor* separator_color = [UIColor colorWithRed:10.0/255.0 green:28.0/255.0 blue:148.0/255.0 alpha:1.0];
    [self.lbtable setSeparatorColor:separator_color];
    
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
        lbtable.hidden = FALSE;
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
    lbtable.hidden = FALSE;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return kLBNum + kSkippedRows;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kRowHeight;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"LeaderboardScreenCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Skip the first few rows
    if (indexPath.row >= kSkippedRows)
    {
        UIColor* text_color = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
        UIColor* background_color = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
        UIFont* text_font = [UIFont fontWithName:@"Marker Felt" size:19.0f];
        CGFloat constrainedSize = 265.0f;
        NSString* lbtext = [[[[LeaderboardMgr getInstance] leaderboards] objectAtIndex:(indexPath.row - kSkippedRows)] lbName];
        
        CGSize sizeText = [lbtext sizeWithFont:text_font
                             constrainedToSize:CGSizeMake(constrainedSize, CGFLOAT_MAX)
                                 lineBreakMode:UILineBreakModeWordWrap];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 0.0, sizeText.width, kRowHeight)];
        label.text = lbtext;
        label.backgroundColor = background_color;
        label.textColor = text_color;
        [label setNumberOfLines:1];
        [label setFont:text_font];
        label.textAlignment = UITextAlignmentLeft;
        
        [cell.contentView addSubview:label];
    }
    else
    {
        // Disable cel
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Skip the first few rows
    if (indexPath.row >= kSkippedRows)
    {
        SingleLeaderboard* leaderboard = [[SingleLeaderboard alloc] initWithNibNameAndIndex:@"SingleLeaderboard" bundle:nil     index:indexPath.row - kSkippedRows];
        [self.navigationController pushFromRightViewController:leaderboard animated:YES];
        
        [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:false];
    }
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
        errorLabel.hidden = FALSE;
    }
}

@end
