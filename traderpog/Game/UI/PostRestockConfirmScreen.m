//
//  PostRestockConfirmScreen.m
//  traderpog
//
//  Created by Aaron Khoo on 10/17/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "UINavigationController+Pog.h"
#import "GameColors.h"
#import "ImageManager.h"
#import "Player.h"
#import "PogUIUtility.h"
#import "PostRestockConfirmScreen.h"

static const float kContentBorderWidth = 6.0f;
static const float kContentBorderCornerRadius = 8.0f;

@interface PostRestockConfirmScreen ()
- (void) didPressClose:(id)sender;
@end

@implementation PostRestockConfirmScreen
@synthesize post = _post;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self)
    {
        _post = nil;
    }
    return self;
}

- (void) dealloc
{
    [self.closeCircle removeButtonTarget];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.alpha = 1.0f;
    [PogUIUtility setBorderOnView:self.contentView
                            width:kContentBorderWidth
                            color:[GameColors borderColorScanWithAlpha:1.0f]
                     cornerRadius:kContentBorderCornerRadius];
    [self.contentView setBackgroundColor:[GameColors bubbleColorFlyersWithAlpha:1.0f]];
    [self.closeCircle setBorderColor:[GameColors borderColorScanWithAlpha:1.0f]];
    [self.closeCircle setButtonTarget:self action:@selector(didPressClose:)];
    
    // It cost 100 coins to restock
    if ([[Player getInstance] bucks] < 100)
    {
        // Disable purchase if less than 100 coins
        [self.restockButton setEnabled:FALSE];
        [self.restockButton setTitle:@"Not enough coins" forState:UIControlStateNormal];
    }
    else
    {
        [self.restockButton setEnabled:TRUE];
        [self.restockButton setTitle:@"Restock" forState:UIControlStateNormal];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
    [self.closeCircle removeButtonTarget];
    [self setContentView:nil];
    [self setCloseCircle:nil];
    [self setImageView:nil];
    [super viewDidUnload];
}

#pragma mark - button actions
- (void) didPressClose:(id)sender
{
    [self closeScreen];
}

- (IBAction)didPressRestock:(id)sender
{
    NSLog(@"Restock");
    [_post restockPostSupply];
    [self closeScreen];
}

- (void)closeScreen
{
    self.post = nil;
    [UIView animateWithDuration:0.2f
                     animations:^(void){
                         self.view.alpha = 0.0f;
                     }
                     completion:^(BOOL finished){
                         [self.navigationController popViewControllerAnimated:NO];
                     }];
}

@end
