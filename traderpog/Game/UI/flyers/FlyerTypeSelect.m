//
//  FlyerTypeSelect.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 11/25/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "FlyerTypeSelect.h"
#import "FlyerTypeSelectCell.h"
#import "FlyerTypes.h"
#import "FlyerType.h"
#import "FlyerLabFactory.h"
#import "ImageManager.h"
#import "SoundManager.h"
#import "GameManager.h"
#import "GameColors.h"
#import "FlyerBuyConfirmScreen.h"
#import "FlyerMgr.h"

@interface FlyerTypeSelect ()
{
    NSMutableArray* _flyerTypes;
}
@end

@implementation FlyerTypeSelect

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.closeCircle setButtonTarget:self action:@selector(didPressClose:)];
    
    NSArray* sortedFlyerTypes = [[FlyerTypes getInstance] sortedTypes];
    _flyerTypes = [NSMutableArray arrayWithArray:sortedFlyerTypes];
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
    // Dispose of any resources that can be recreated.
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
    NSInteger num = [_flyerTypes count];
    return num;
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
    static NSString *CellIdentifier = @"FlyerTypeSelectCell";
    
    FlyerTypeSelectCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        UINib *cellNib = [UINib nibWithNibName:@"FlyerTypeSelectCell" bundle:nil];
        [cellNib instantiateWithOwner:self options:nil];
        cell = self.flyerCell;
        self.flyerCell = nil;
    }
    
    NSInteger index = [indexPath row];
    if(index < [_flyerTypes count])
    {
        FlyerType* flyerType = [_flyerTypes objectAtIndex:index];
        
        // flyer image
        NSString* flyerTypeName = [flyerType sideimg];
        NSString* imageName = [[FlyerLabFactory getInstance] sideImageForFlyerTypeNamed:flyerTypeName tier:1 colorIndex:0];
        UIImage* flyerImage = [[ImageManager getInstance] getImage:imageName];
        [cell.flyerImageView setImage:flyerImage];
        
        if([FlyerTypes maxFlyersForFlyerTypeId:[flyerType flyerId]] <= [[FlyerMgr getInstance] numFlyersOfFlyerType:flyerType])
        {
            [cell.contentView setBackgroundColor:[UIColor darkGrayColor]];
        }
        else
        {
            [cell.contentView setBackgroundColor:[UIColor whiteColor]];
        }
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = [indexPath row];
    FlyerType* flyerType = [_flyerTypes objectAtIndex:index];
    
    if([FlyerTypes maxFlyersForFlyerTypeId:[flyerType flyerId]] > [[FlyerMgr getInstance] numFlyersOfFlyerType:flyerType])
    {
        FlyerBuyConfirmScreen* next = [[FlyerBuyConfirmScreen alloc] initWithFlyerType:flyerType];
        [[GameManager getInstance].gameViewController pushModalNavViewController:next];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
