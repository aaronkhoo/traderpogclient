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

@interface FlyerTypeSelect ()
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
    NSInteger num = [[[FlyerTypes getInstance] sortedTypes] count];
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
    
    NSArray* flyerTypes = [[FlyerTypes getInstance] sortedTypes];
    NSInteger index = [indexPath row];
    if(index < [flyerTypes count])
    {
        FlyerType* flyerType = [flyerTypes objectAtIndex:index];
        
        // flyer image
        NSString* flyerTypeName = [flyerType sideimg];
        NSString* imageName = [[FlyerLabFactory getInstance] sideImageForFlyerTypeNamed:flyerTypeName tier:1 colorIndex:0];
        UIImage* flyerImage = [[ImageManager getInstance] getImage:imageName];
        [cell.flyerImageView setImage:flyerImage];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

@end
