//
//  FlyerBuyConfirmScreen.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/18/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "FlyerBuyConfirmScreen.h"
#import "PogUIUtility.h"
#import "GameColors.h"
#import "FlyerType.h"
#import "ImageManager.h"
#import "FlyerLabFactory.h"

static const float kContentBorderWidth = 6.0f;
static const float kContentBorderCornerRadius = 8.0f;

@interface FlyerBuyConfirmScreen ()
{
    FlyerType* _flyerType;
}
- (void) didPressClose:(id)sender;
- (void) didPressBuy:(id)sender;
- (void) setupContent;
@end

@implementation FlyerBuyConfirmScreen

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    NSAssert(false, @"must use initWithFlyerType: to create FlyerBuyConfirmScreen");
    return nil;
}

- (id) initWithFlyerType:(FlyerType *)flyerType
{
    self = [super initWithNibName:@"FlyerBuyConfirmScreen" bundle:nil];
    if(self)
    {
        _flyerType = flyerType;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.alpha = 1.0f;
    
    // colors and borders
    [PogUIUtility setBorderOnView:self.contentView
                            width:kContentBorderWidth
                            color:[GameColors borderColorScanWithAlpha:1.0f]
                     cornerRadius:kContentBorderCornerRadius];
    [self.contentView setBackgroundColor:[GameColors bubbleColorFlyersWithAlpha:1.0f]];
    [self.closeCircle setBorderColor:[GameColors borderColorScanWithAlpha:1.0f]];
    [self.closeCircle setButtonTarget:self action:@selector(didPressClose:)];
    [self.buyCircle setBorderColor:[GameColors borderColorScanWithAlpha:1.0f]];
    [self.buyCircle setButtonTarget:self action:@selector(didPressBuy:)];
    
    [self setupContent];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setCloseCircle:nil];
    [self setBuyCircle:nil];
    [self setContentView:nil];
    [self setImageView:nil];
    [self setFlyerNameLabel:nil];
    [self setFlyerDescLabel:nil];
    [super viewDidUnload];
}

#pragma mark - internals
- (void) setupContent
{
    // image
    NSString* flyerTypeName = [_flyerType sideimg];
    NSString* imageName = [[FlyerLabFactory getInstance] sideImageForFlyerTypeNamed:flyerTypeName tier:1 colorIndex:0];
    UIImage* flyerImage = [[ImageManager getInstance] getImage:imageName];
    [self.imageView setImage:flyerImage];
    
    // flyer name
    [self.flyerNameLabel setText:[_flyerType name]];
    
    // flyer descriptions
    [self.flyerDescLabel setText:[_flyerType desc]];
}

#pragma mark - button actions
- (void) didPressClose:(id)sender
{
    [UIView animateWithDuration:0.2f
                     animations:^(void){
                         self.view.alpha = 0.0f;
                     }
                     completion:^(BOOL finished){
                         [self.navigationController popViewControllerAnimated:NO];
                     }];
}

- (void) didPressBuy:(id)sender
{
    [self didPressClose:sender];
}

@end
