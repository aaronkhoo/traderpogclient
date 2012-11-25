//
//  FlyerTypeSelect.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 11/25/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "FlyerTypeSelect.h"
#import "FlyerTypeSelectCell.h"

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
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 6;
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
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

@end
