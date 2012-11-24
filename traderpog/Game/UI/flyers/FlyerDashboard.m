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
#import "TradePost.h"
#import "TradeItemTypes.h"
#import "TradeItemType.h"
#import "ImageManager.h"
#import "GameManager.h"

@interface FlyerDashboard ()
{
    NSMutableArray* _availableFlyers;
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
    _availableFlyers = [NSMutableArray arrayWithCapacity:5];
    for(Flyer* cur in [[FlyerMgr getInstance] playerFlyers])
    {
//        if((kFlyerStateIdle == [cur state]) ||
//           (kFlyerStateLoaded == [cur state]))
        {
            [_availableFlyers addObject:cur];
        }
    }
}

#pragma mark - updates from game sim
- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context
{
    if([keyPath isEqualToString:kGameManagerPerSecondElapsed])
    {
        NSLog(@"flyer dashboard one second");
    }
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

/*
 - (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
 {
 return kRowHeight;
 }
 */


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
        
        // flyer image
        UIImageView* imageView = cell.flyerImageView;
        [imageView setImage:[flyer imageForState:kFlyerStateIdle]];
        
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
                break;
                
            case kFlyerStateLoading:
                [cell.statusLabel setText:@"Loading"];
                break;
                
            case kFlyerStateWaitingToLoad:
                [cell.statusLabel setText:@"Awaiting Loader"];
                break;
                
            default:
                [cell.statusLabel setText:@"Ready"];
                break;
        }
        [cell.timeLabel setHidden:YES];
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
        [self.navigationController popToRootViewControllerAnimated:NO];
        [[GameManager getInstance] haltMapAnnotationCalloutsForDuration:0.1f];
        
        Flyer* flyer = [_availableFlyers objectAtIndex:[indexPath row]];
        [[GameManager getInstance] wheel:nil commitOnFlyer:flyer];
    }
    else
    {
        // TODO: buy new flyer
    }
}

@end
