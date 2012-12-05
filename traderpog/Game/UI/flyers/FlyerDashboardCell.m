//
//  FlyerDashboardCell.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 11/18/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "FlyerDashboardCell.h"
#import "Flyer.h"
#import "FlyerLabViewController.h"
#import "GameManager.h"
#import "SoundManager.h"

@implementation FlyerDashboardCell
@synthesize flyer;
@synthesize navController;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.flyer = nil;
        self.navController = nil;
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) prepareForReuse
{
    self.flyer = nil;
    self.navController = nil;
}

#pragma mark - button actions
- (IBAction)didPressUpgrade:(id)sender
{
    if([self flyer])
    {
        [[SoundManager getInstance] playClip:@"Pog_SFX_PopUP_Level2"];
        FlyerLabViewController* next = [[FlyerLabViewController alloc] initWithNibName:@"FlyerLabViewController" bundle:nil];
        next.flyer = [self flyer];
        [self.navController pushViewController:next animated:YES];
    }
}

- (IBAction)didPressMap:(id)sender
{
    if([self flyer])
    {
        [[SoundManager getInstance] playClip:@"Pog_SFX_PopUP_Level2"];
        [self.navController popToRootViewControllerAnimated:NO];
        [[GameManager getInstance] haltMapAnnotationCalloutsForDuration:0.1f];
        [[GameManager getInstance] wheel:nil commitOnFlyer:[self flyer]];
    }
}

@end
