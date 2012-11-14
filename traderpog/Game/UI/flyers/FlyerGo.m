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

static const NSInteger kGoCellTagImage = 10;
static const NSInteger kGoCellTagDistance = 11;

@interface FlyerGo ()
{
    NSMutableArray* _availableFlyers;
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
    for(Flyer* cur in [[FlyerMgr getInstance] playerFlyers])
    {
        if((kFlyerStateIdle == [cur state]) ||
           (kFlyerStateLoaded == [cur state]))
        {
            [_availableFlyers addObject:cur];
        }
    }
}

#pragma mark - button actions
- (void) didPressClose:(id)sender
{
    [[SoundManager getInstance] playClip:@"Pog_SFX_Nav_up"];
    [self.navigationController popViewControllerAnimated:NO];
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
    static NSString *CellIdentifier = @"FlyerGoCell";
    
    FlyerGoCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        UINib *goCellNib = [UINib nibWithNibName:@"FlyerGoCell" bundle:nil];
        [goCellNib instantiateWithOwner:self options:nil];
        cell = self.goCell;
        self.goCell = nil;
    }
    
    if([indexPath row] < [_availableFlyers count])
    {
        Flyer* flyer = [_availableFlyers objectAtIndex:[indexPath row]];

        // image
        UIImageView* imageView = cell.imageView;
        [imageView setImage:[flyer imageForState:kFlyerStateIdle]];
        
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
        
        [cell.goSubview setHidden:NO];
        [cell.addFlyerSubview setHidden:YES];
    }
    else
    {
        [cell.goSubview setHidden:YES];
        [cell.addFlyerSubview setHidden:NO];
    }
    return cell;
}

#pragma mark - UITableViewDelegate

@end
