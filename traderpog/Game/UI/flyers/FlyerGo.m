//
//  FlyerGo.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 11/6/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "FlyerGo.h"
#import "SoundManager.h"
#import "GameColors.h"
#import "UINavigationController+Pog.h"
#import "FlyerMgr.h"
#import "Flyer.h"
#import "FlyerGoCell.h"
#import "TradePost.h"
#import "TradeItemTypes.h"
#import "TradeItemType.h"
#import "ImageManager.h"
#import "GameManager.h"

static const NSInteger kGoCellTagImage = 10;
static const NSInteger kGoCellTagDistance = 11;

@interface FlyerGo ()
{
    NSMutableArray* _availableFlyers;
    NSMutableArray* _busyFlyers;
    TradePost* _tradePost;
}
@end

@implementation FlyerGo

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    NSAssert(false, @"Call initWithPost to create FlyerGo instead");
    return nil;
}

- (id)initWithPost:(TradePost *)post
{
    self = [super initWithNibName:@"FlyerGo" bundle:nil];
    if (self)
    {
        _tradePost = post;
    }
    return self;
}

- (void) dealloc
{
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.closeCircle setBorderColor:[GameColors borderColorScanWithAlpha:1.0f]];
    [self.closeCircle setButtonTarget:self action:@selector(didPressClose:)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [self setCloseCircle:nil];
    [self setTableView:nil];
    [self setGoCell:nil];
    [super viewDidUnload];
}

- (void) viewWillAppear:(BOOL)animated
{
    _availableFlyers = [NSMutableArray arrayWithCapacity:5];
    _busyFlyers = [NSMutableArray arrayWithCapacity:5];
    for(Flyer* cur in [[FlyerMgr getInstance] playerFlyers])
    {
        if((kFlyerStateIdle == [cur state]) ||
           (kFlyerStateLoaded == [cur state]))
        {
            [_availableFlyers addObject:cur];
        }
        else
        {
            [_busyFlyers addObject:cur];
        }
    }
}

- (Flyer*) getFlyerAtIndex:(NSInteger)curIndex
{
    Flyer* flyer;
    if(curIndex < [_availableFlyers count])
    {
        flyer = [_availableFlyers objectAtIndex:curIndex];
    }
    else
    {
        curIndex -= [_availableFlyers count];
        flyer = [_busyFlyers objectAtIndex:curIndex];
    }
    return flyer;
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
    return [_availableFlyers count] + [_busyFlyers count] + 1;
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
    static NSString *CellIdentifier = @"FlyerGoCell";
    
    FlyerGoCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        UINib *goCellNib = [UINib nibWithNibName:@"FlyerGoCell" bundle:nil];
        [goCellNib instantiateWithOwner:self options:nil];
        cell = self.goCell;
        self.goCell = nil;
    }
    
    if([indexPath row] < ([_availableFlyers count] + [_busyFlyers count]))
    {
        NSInteger curIndex = [indexPath row];
        Flyer* flyer = [self getFlyerAtIndex:curIndex];
        BOOL flyerIsBusy = NO;
        if(curIndex >= [_availableFlyers count])
        {
            flyerIsBusy = YES;
            [cell.busyFlyerSubview setHidden:NO];
        }
        else
        {
            [cell.busyFlyerSubview setHidden:YES];
            [cell.goSubview setHidden:NO];

            // distance from post
            CLLocation* postLoc = [[CLLocation alloc] initWithLatitude:_tradePost.coord.latitude longitude:_tradePost.coord.longitude];
            CLLocation* flyerLoc = [[CLLocation alloc] initWithLatitude:flyer.coord.latitude longitude:flyer.coord.longitude];
            CLLocationDistance dist = [postLoc distanceFromLocation:flyerLoc];
            if(1000.0 < dist)
            {
                // kilometers
                [cell.distLabel setText:[NSString stringWithFormat:@"%.0fkm", dist / 1000.0]];
            }
            else
            {
                // meters
                [cell.distLabel setText:[NSString stringWithFormat:@"%.0fm", dist]];
            }
        }

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
            [cell.capLabel2 setText:capacityString];
        }
        else
        {
            [cell.capLabel setText:@"FULL"];
            [cell.capLabel2 setText:@"FULL"];
        }

        NSString* postItemId = [_tradePost itemId];
        NSString* flyerItemId = [flyer.inventory itemId];
        if(!flyerItemId)
        {
            flyerItemId = [flyer.inventory orderItemId];
        }
        
        if(flyerItemId)
        {
            TradeItemType* itemType = [[TradeItemTypes getInstance] getItemTypeForId:flyerItemId];
            
            // item image
            if(cap == remainingCap)
            {
                [cell.itemImageView setImage:nil];
                [cell.itemImageView setHidden:YES];
            }
            else
            {
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
        }
        else
        {
            [cell.itemImageView setImage:nil];
            [cell.itemImageView setHidden:YES];
        }
        
        // if FULL or different item, gray out cell
        if((!remainingCap) ||
           ((flyerItemId) && (![flyerItemId isEqualToString:postItemId])) ||
           (flyerIsBusy))
        {
            [cell.contentView setBackgroundColor:[UIColor lightGrayColor]];
        }
        else
        {
            [cell.contentView setBackgroundColor:[UIColor whiteColor]];
        }
        
        [cell.addFlyerSubview setHidden:YES];
    }
    else
    {
        [cell.busyFlyerSubview setHidden:YES];
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

        Flyer* flyer = [self getFlyerAtIndex:[indexPath row]];
        [[GameManager getInstance] wheel:nil commitOnFlyer:flyer];
    }
    else if([indexPath row] < ([_availableFlyers count] + [_busyFlyers count]))
    {
        // busy flyer, do nothing
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
    else
    {
        // TODO: buy new flyer
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}
@end
