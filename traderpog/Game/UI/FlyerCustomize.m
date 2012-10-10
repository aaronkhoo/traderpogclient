//
//  FlyerCustomize.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/6/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "FlyerCustomize.h"
#import "GameColors.h"
#import "UINavigationController+Pog.h"
#import "Flyer.h"
#import "FlyerLabFactory.h"
#import "FlyerUpgradePack.h"
#import "GameAnim.h"
#import "PogUIUtility.h"
#import "ImageManager.h"

static const float kContentBorderWidth = 6.0f;
static const float kContentBorderCornerRadius = 8.0f;

@interface FlyerCustomize ()
- (void) setupContent;
- (void) didPressBuy:(id)sender;
- (void) didPressClose:(id)sender;
@end

@implementation FlyerCustomize

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    NSAssert(false, @"must call initWithFlyer to create FlyerUpgrade");
    return nil;
}

- (id) initWithFlyer:(Flyer *)flyer
{
    self = [super initWithNibName:@"FlyerCustomize" bundle:nil];
    if (self)
    {
        _flyer = flyer;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
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
}

- (void)viewDidUnload
{
    [self setCloseCircle:nil];
    [self setContentView:nil];
    [self setBuyCircle:nil];
    [self setOptionOriginal:nil];
    [self setOption1:nil];
    [self setOption2:nil];
    [self setOption3:nil];
    [self setPriceLabel:nil];
    [self setCoinImageView:nil];
    [self setImageView:nil];
    [super viewDidUnload];
}

#pragma mark - internal methods
- (void) didPressClose:(id)sender
{
    [self.navigationController popFadeOutViewControllerAnimated:YES];
}

- (void) didPressBuy:(id)sender
{
    [self didPressClose:sender];    
}

- (void) setupContent
{
    // pack info
    //FlyerColorPack* pack = [[FlyerLabFactory getInstance] colorPackAtIndex:0 forFlyerTypeNamed:@"flyer_glider"];
    /*
    FlyerUpgradePack* pack = [[FlyerLabFactory getInstance] upgradeForTier:nextTier];
    NSString* speedText = [NSString stringWithFormat:@"%dx", (unsigned int)[pack speedFactor]];
    NSString* capacityText = [NSString stringWithFormat:@"%dx", (unsigned int)[pack capacityFactor]];
    [self.speedLevel setText:speedText];
    [self.capacityLevel setText:capacityText];
    [self.secondaryTitleLabel setText:[pack secondTitle]];
    UIImage* image = [[ImageManager getInstance] getImage:[pack img]];
    [self.imageView setImage:image];
    */
    
    // image
    NSString* imageName = [[FlyerLabFactory getInstance] sideImageForFlyerTypeNamed:@"flyer_glider" tier:[_flyer curUpgradeTier] colorIndex:[_flyer curColor]];
    UIImage* image = [[ImageManager getInstance] getImage:imageName];
    [self.imageView setImage:image];
    

    // coin image and label
    [[GameAnim getInstance] refreshImageView:[self coinImageView] withClipNamed:@"coin_shimmer"];
    [self.coinImageView startAnimating];
    
    // price
    NSString* priceText = [PogUIUtility commaSeparatedStringFromUnsignedInt:[[FlyerLabFactory getInstance] priceForColorCustomization]];
    [self.priceLabel setText:priceText];
}

@end
