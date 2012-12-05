//
//  FlyerDashboard.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 11/18/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "FlyerDashboard.h"
#import "SoundManager.h"
#import "GameColors.h"
#import "UINavigationController+Pog.h"
#import "FlyerMgr.h"
#import "Flyer.h"
#import "FlyerDashboardCell.h"
#import "TradePostMgr.h"
#import "TradePost.h"
#import "TradeItemTypes.h"
#import "TradeItemType.h"
#import "ImageManager.h"
#import "GameManager.h"
#import "PogUIUtility.h"
#import "FlyerTypes.h"
#import "FlyerTypeSelect.h"

static const CGFloat kRowHeight = 44.0f;
static const CGFloat kRowHeightSelected = 100.0f;

@interface FlyerDashboard ()
{
    NSMutableArray* _availableFlyers;
    NSInteger _selectedRow;
}
@end

@implementation FlyerDashboard

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[GameManager getInstance] addObserver:self forKeyPath:kGameManagerPerSecondElapsed options:0 context:nil];
    }
    return self;
}

- (void) dealloc
{
    [[GameManager getInstance] removeObserver:self forKeyPath:kGameManagerPerSecondElapsed];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.closeCircle setBorderColor:[GameColors borderColorScanWithAlpha:1.0f]];
    [self.closeCircle setButtonTarget:self action:@selector(didPressClose:)];

    _availableFlyers = [NSMutableArray arrayWithArray:[[FlyerMgr getInstance] playerFlyers]];
    _selectedRow = -1;
}

- (void)viewDidUnload {
    [self setCloseCircle:nil];
    [self setTableView:nil];
    [self setFlyerCell:nil];
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) viewWillAppear:(BOOL)animated
{
    [self.tableView reloadData];
}

#pragma mark - updates from game sim
- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context
{
    if([keyPath isEqualToString:kGameManagerPerSecondElapsed])
    {
        BOOL shouldReload = NO;
        for(Flyer* cur in _availableFlyers)
        {
            if((kFlyerStateEnroute == [cur state]) || (kFlyerStateLoading == [cur state]))
            {
                shouldReload = YES;
                break;
            }
        }
        if(shouldReload)
        {
            [self.tableView reloadData];
        }
    }
}

- (NSTimeInterval) getRemainingLoadTimeForFlyer:(Flyer*)flyer
{
    NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:[flyer stateBegin]];
    NSTimeInterval remaining = [flyer getFlyerLoadDuration] - elapsed;
    if(0.0f > remaining)
    {
        remaining = 0.0f;
    }
    return remaining;
}

#pragma mark - button actions
- (void) didPressClose:(id)sender
{
    [[SoundManager getInstance] playClip:@"Pog_SFX_Nav_up"];
    [self.navigationController popViewControllerAnimated:NO];
    [[GameManager getInstance] popGameStateToLoop];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_availableFlyers count] + 1;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = kRowHeight;
    if([indexPath row] == _selectedRow)
    {
        height = kRowHeightSelected;
    }
    return height;
}



- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"FlyerDashboardCell";
    
    FlyerDashboardCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        UINib *cellNib = [UINib nibWithNibName:@"FlyerDashboardCell" bundle:nil];
        [cellNib instantiateWithOwner:self options:nil];
        cell = self.flyerCell;
        self.flyerCell = nil;
    }
    
    if([indexPath row] < [_availableFlyers count])
    {
        Flyer* flyer = [_availableFlyers objectAtIndex:[indexPath row]];
        cell.flyer = flyer;
        cell.navController = self.navigationController;
        
        // flyer image
        UIImageView* imageView = cell.flyerImageView;
        [imageView setImage:[flyer imageForState:kFlyerStateIdle]];
        [cell.flyerImageView setHidden:NO];

        // capacity
        unsigned int remainingCap = [flyer remainingCapacity];
        unsigned int cap = [flyer capacity];
        if(remainingCap)
        {
            NSString* capacityString = [NSString stringWithFormat:@"%d/%d", cap - remainingCap, cap];
            [cell.capLabel setText:capacityString];
        }
        else
        {
            [cell.capLabel setText:@"FULL"];
        }
        
        NSString* flyerItemId = [flyer.inventory itemId];
        if(!flyerItemId)
        {
            flyerItemId = [flyer.inventory orderItemId];
        }
        
        if(flyerItemId)
        {
            TradeItemType* itemType = [[TradeItemTypes getInstance] getItemTypeForId:flyerItemId];
            
            // item image
            [cell.itemImageView setHidden:NO];
            NSString* itemName = nil;
            if(itemType)
            {
                itemName = [itemType name];
                NSString* itemImagePath = [itemType imgPath];
                UIImage* itemImage = [[ImageManager getInstance] getImage:itemImagePath];
                [cell.itemImageView setImage:itemImage];
            }
        }
        else
        {
            [cell.itemImageView setImage:nil];
            [cell.itemImageView setHidden:YES];
        }
        
        // flyer status
        switch ([flyer state])
        {
            case kFlyerStateEnroute:
                [cell.statusLabel setText:@"Enroute"];
                [cell.timeLabel setHidden:NO];
                [cell.timeLabel setText:[PogUIUtility stringFromTimeInterval:[flyer timeTillDest]]];
                break;
                
            case kFlyerStateLoading:
                [cell.statusLabel setText:@"Loading"];
                [cell.timeLabel setHidden:NO];
                [cell.timeLabel setText:[PogUIUtility stringFromTimeInterval:[self getRemainingLoadTimeForFlyer:flyer]]];
                break;
                
            case kFlyerStateWaitingToLoad:
                [cell.statusLabel setText:@"Awaiting Loader"];
                [cell.timeLabel setHidden:YES];
                break;
                
            default:
                [cell.statusLabel setText:@"Ready"];
                if([[TradePostMgr getInstance] isFlyerAtHome:flyer])
                {
                    [cell.timeLabel setHidden:NO];
                    [cell.timeLabel setText:@"At Home"];
                }
                else
                {
                    [cell.timeLabel setHidden:YES];
                }
                break;
        }
        [cell.goSubview setHidden:NO];
        [cell.addFlyerSubview setHidden:YES];
    }
    else
    {
        [cell.goSubview setHidden:YES];
        [cell.addFlyerSubview setHidden:NO];
        [cell.flyerImageView setHidden:YES];
        [cell.itemImageView setHidden:YES];
    }
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath row] < [_availableFlyers count])
    {
        [[SoundManager getInstance] playClip:@"Pog_SFX_PopUP_Level1"];
        _selectedRow = [indexPath row];
        
        // this animates row height changes
        [tableView beginUpdates];
        [tableView endUpdates];
    }
    else
    {
        [[SoundManager getInstance] playClip:@"Pog_SFX_PopUP_Level1"];
        FlyerTypeSelect* next = [[FlyerTypeSelect alloc] initWithNibName:@"FlyerTypeSelect" bundle:nil];
        [[GameManager getInstance].gameViewController pushModalNavViewController:next];
        _selectedRow = -1;
    }
}

@end
