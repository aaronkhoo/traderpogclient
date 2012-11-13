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

static const NSInteger kGoCellTagImage = 10;
static const NSInteger kGoCellTagDistance = 11;

@interface FlyerGo ()
{
    NSMutableArray* _availableFlyers;
}
@end

@implementation FlyerGo

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
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
    }
    return cell;
}

#pragma mark - UITableViewDelegate

@end
