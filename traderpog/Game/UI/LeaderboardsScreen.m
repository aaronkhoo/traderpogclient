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
#import "MBProgressHUD.h"
#import "Player.h"
#import "SingleLeaderboard.h"
#import "GameColors.h"

static CGFloat const kRowHeight = 40.0;
static CGFloat const kImageSize = 35.0;

@implementation LeaderboardsScreen
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
    
    UIColor* separator_color = [UIColor colorWithRed:69.0/255.0 green:94.0/255.0 blue:230.0/255.0 alpha:1.0];
    [self.lbtable setSeparatorColor:separator_color];
    [self.closeCircle setBorderColor:[GameColors borderColorScanWithAlpha:1.0f]];
    [self.closeCircle setButtonTarget:self action:@selector(didPressClose:)];
    
    if ([[LeaderboardMgr getInstance] needsRefresh])
    {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.labelText = @"Retrieving leaderboards";
        [[LeaderboardMgr getInstance] retrieveLeaderboardFromServer];
    }
    else
    {
        lbtable.hidden = FALSE;
    }
}

- (void)viewDidUnload
{
    [self setCloseCircle:nil];
    [[LeaderboardMgr getInstance] setDelegate:nil];
}

- (void)didPressClose:(id)sender
{
    [self.navigationController popToRightViewControllerAnimated:YES];
}

- (void)updateLeaderboardUI
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    lbtable.hidden = FALSE;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

// Customize the number of rows in the table view.

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (kLBNum * 2) + 3;
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
    
    // Draw vertical lines
    UIView *vertLine1;
    UIView *vertLine2;
    if (indexPath.row == 0)
    {
        vertLine1 = [[UIView alloc] initWithFrame:CGRectMake(50.0, 7.0, 1.0, kRowHeight - 7)];
        vertLine2 = [[UIView alloc] initWithFrame:CGRectMake(55.0, 7.0, 1.0, kRowHeight - 7)];
    }
    else
    {
        vertLine1 = [[UIView alloc] initWithFrame:CGRectMake(50.0, 0.0, 1.0, kRowHeight)];
        vertLine2 = [[UIView alloc] initWithFrame:CGRectMake(55.0, 0.0, 1.0, kRowHeight)];
    }
    
    UIColor* vertLineColor = [UIColor colorWithRed:255.0/255.0 green:95.0/255.0 blue:79.0/255.0 alpha:1.0];
    vertLine1.backgroundColor = vertLineColor;
    [cell addSubview:vertLine1];
    vertLine2.backgroundColor = vertLineColor;
    [cell addSubview:vertLine2];
    
    if (((indexPath.row % 2) == 1) && (indexPath.row < (kLBNum * 2)))
    {
        // Display the right image
        NSString *filePath = nil;
        switch (indexPath.row / 2) {
            case 0:
                filePath = [[NSBundle mainBundle] pathForResource:@"icon_lboard_safebox" ofType:@"png"];
                break;
                
            case 1:
                filePath = [[NSBundle mainBundle] pathForResource:@"icon_lboard_travelled" ofType:@"png"];
                break;
                
            case 2:
                filePath = [[NSBundle mainBundle] pathForResource:@"icon_lboard_distance" ofType:@"png"];
                break;
                
            case 3:
                filePath = [[NSBundle mainBundle] pathForResource:@"icon_lboard_posts" ofType:@"png"];
                break;
                
            default:
                break;
        }
        if (filePath)
        {
            NSData *imageData = [NSData dataWithContentsOfFile:filePath];
            UIImage *image = [[UIImage alloc] initWithData:imageData];
            UIImageView *lbImgView = [[UIImageView alloc] initWithImage:image];
            //set contentMode to scale aspect to fit
            lbImgView.contentMode = UIViewContentModeScaleAspectFit;
            
            //change width of frame
            CGRect frame = lbImgView.frame;
            frame.origin.x = 5.0;
            frame.size.height = kRowHeight;
            frame.size.width = kRowHeight;
            lbImgView.frame = frame;
            [cell.contentView addSubview:lbImgView];
        }
        
        UIColor* text_color = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
        UIColor* background_color = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
        UIFont* text_font = [UIFont fontWithName:@"Marker Felt" size:19.0f];
        CGFloat constrainedSize = 265.0f;
        NSString* lbtext = [[[[LeaderboardMgr getInstance] leaderboards] objectAtIndex:(indexPath.row / 2)] lbName];
        
        CGSize sizeText = [lbtext sizeWithFont:text_font
                             constrainedToSize:CGSizeMake(constrainedSize, CGFLOAT_MAX)
                                 lineBreakMode:UILineBreakModeWordWrap];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(70.0, 0.0, sizeText.width, kRowHeight)];
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
    if ((indexPath.row % 2) == 1)
    {
        SingleLeaderboard* leaderboard = [[SingleLeaderboard alloc] initWithNibNameAndIndex:@"SingleLeaderboard" bundle:nil     index:(indexPath.row / 2)];
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
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        errorLabel.hidden = FALSE;
    }
}

@end
