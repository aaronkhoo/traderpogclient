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
#import "MathUtils.h"
#import "Player.h"
#import "SingleLeaderboard.h"
#import "GameColors.h"
#import "UrlImage.h"
#import "UrlImageManager.h"

static NSString* const kKeyIndex = @"index";
static NSString* const kKeyName = @"name";
static NSString* const kKeyFbid= @"fbid";
static NSString* const kKeyValue = @"value";
static NSString* const kFbPictureUrl = @"https://graph.facebook.com/%@/picture";
static CGFloat const kRowHeight = 30.0;

@implementation SingleLeaderboard
@synthesize leaderboardName;
@synthesize leaderboardTable;

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
                [rowDict setObject:[current_row fbid] forKey:kKeyFbid];
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
    
    UIColor* separator_color = [UIColor colorWithRed:10.0/255.0 green:28.0/255.0 blue:148.0/255.0 alpha:1.0];
    [self.leaderboardTable setSeparatorColor:separator_color];
    [self.closeCircle setBorderColor:[GameColors borderColorScanWithAlpha:1.0f]];
    [self.closeCircle setButtonTarget:self action:@selector(didPressClose:)];
}

- (void)didPressClose:(id)sender
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kRowHeight;
}

// Customize appearance of labels
- (UILabel*)customizeLabel:(NSString*)text
                      font:(UIFont*)font
                     color:(UIColor*)color
                   bgcolor:(UIColor*)bgcolor
                     align:(UITextAlignment)align
                    height:(CGFloat)height
                      xval:(CGFloat)xval
                     yval:(CGFloat)yval
{
    CGFloat constrainedSize = 265.0f;
    CGSize sizeText = [text sizeWithFont:font
                                 constrainedToSize:CGSizeMake(constrainedSize, CGFLOAT_MAX)
                                     lineBreakMode:UILineBreakModeWordWrap];
    CGRect rect;
    if (align == UITextAlignmentRight)
    {
        // Special case right justified labels
        rect = CGRectMake(xval - sizeText.width, yval, sizeText.width, height);
    }
    else
    {
        rect = CGRectMake(xval, yval, sizeText.width, height);
    }
    UILabel *label = [[UILabel alloc] initWithFrame:rect];
    label.text = text;
    label.backgroundColor = bgcolor;
    label.textColor = color;
    [label setNumberOfLines:1];
    [label setFont:font];
    label.textAlignment = align;
    return label;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    static NSString *CellIdentifier = @"LeaderboardRowCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (indexPath.row == 0)
    {
        UIColor* text_color = [UIColor colorWithRed:135.0/255.0 green:132.0/255.0 blue:132.0/255.0 alpha:1.0];
        UIColor* background_color = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
        UIFont* text_font = [UIFont fontWithName:@"Marker Felt" size:19.0f];
        
        // Create "week of" on the left side
        UILabel* leftLabel = [self customizeLabel:@"Week of:"
                                             font:text_font
                                            color:text_color
                                          bgcolor:background_color
                                            align:UITextAlignmentLeft
                                           height:tableView.rowHeight
                                             xval:5.0
                                             yval:0.0];
        [cell.contentView addSubview:leftLabel];
        
        // The start positions for the name column is aligned with the size of the WeekOf label
        _nameStartPosition = leftLabel.frame.size.width;

        // Create date on the right side
        UILabel* rightLabel = [self customizeLabel:_currentWeek
                                              font:text_font
                                             color:text_color
                                           bgcolor:background_color
                                             align:UITextAlignmentRight
                                            height:tableView.rowHeight
                                              xval:cell.frame.size.width-5
                                              yval:0];

        [cell.contentView addSubview:rightLabel];
        
    }
    else if (indexPath.row == 1)
    {
        // do nothing. This is blank.
    }
    else
    {
        NSUInteger index = indexPath.row - 2;
        NSDictionary* currentRow = [_currentRows objectAtIndex:index];
        
        UIColor* index_color = [UIColor colorWithRed:1.0/255.0 green:14.0/255.0 blue:95.0/255.0 alpha:1.0];
        UIColor* background_color = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
        UIFont* index_font = [UIFont fontWithName:@"CourierNewPS-BoldMT" size:15.0f];
        UILabel* leftLabel = [self customizeLabel:[NSString stringWithFormat:@"#%d", [[currentRow objectForKey:kKeyIndex] unsignedIntegerValue]]
                                             font:index_font
                                            color:index_color
                                          bgcolor:background_color
                                            align:UITextAlignmentLeft
                                           height:tableView.rowHeight
                                             xval:5.0
                                             yval:0.0];
        [cell.contentView addSubview:leftLabel];
        
        UIImageView* playerImg = [[UIImageView alloc] initWithFrame:CGRectMake(MAX(_nameStartPosition, leftLabel.frame.size.width), 0.0, kRowHeight, kRowHeight)];
        UrlImage* urlImage = [[UrlImageManager getInstance] getCachedImage:[currentRow objectForKey:kKeyFbid]];
        if(urlImage)
        {
            [playerImg setImage:[urlImage image]];
        }
        else
        {
            
            NSString* pictureUrlString = [NSString stringWithFormat:kFbPictureUrl, [currentRow objectForKey:kKeyFbid]];
            UrlImage* urlImage = [[UrlImage alloc] initWithUrl:pictureUrlString forImageView:playerImg];
            [[UrlImageManager getInstance] insertImageToCache:[currentRow objectForKey:kKeyFbid] image:urlImage];
        }
        [cell.contentView addSubview:playerImg];
        
        UIColor* name_color = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
        UIFont* name_font = [UIFont fontWithName:@"American Typewriter" size:14.0f];
        UILabel* middleLabel = [self customizeLabel:[NSString stringWithFormat:@" %@", [currentRow objectForKey:kKeyName]]
                                               font:name_font
                                              color:name_color
                                            bgcolor:background_color
                                              align:UITextAlignmentLeft
                                             height:tableView.rowHeight
                                               xval:(playerImg.frame.origin.x + playerImg.frame.size.width)
                                               yval:0.0];
        [cell.contentView addSubview:middleLabel];
        
        UIColor* value_color = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
        UIFont* value_font = [UIFont fontWithName:@"AmericanTypewriter-Bold" size:16.0f];
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
        NSString* valueOutput = [formatter stringFromNumber:[currentRow objectForKey:kKeyValue]];
        UILabel* rightLabel = [self customizeLabel:valueOutput
                                             font:value_font
                                            color:value_color
                                          bgcolor:background_color
                                            align:UITextAlignmentRight
                                           height:tableView.rowHeight
                                             xval:cell.frame.size.width-5
                                             yval:0.0];
        [cell.contentView addSubview:rightLabel];
    }
    
    return cell;
}

- (void)viewDidUnload
{
    [self setCloseCircle:nil];
    [super viewDidUnload];
}
@end
