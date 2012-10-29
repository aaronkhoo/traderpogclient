//
//  FlyerUpgrade.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/6/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "FlyerUpgrade.h"
#import "GameColors.h"
#import "UINavigationController+Pog.h"
#import "Flyer.h"
#import "FlyerLabFactory.h"
#import "FlyerUpgradePack.h"
#import "GameAnim.h"
#import "GameManager.h"
#import "GameViewController.h"
#import "GuildMembershipUI.h"
#import "PogUIUtility.h"
#import "ImageManager.h"
#import "Player.h"
#import "Player+Shop.h"
#import "FlyerType.h"
#import "FlyerTypes.h"
#import "SoundManager.h"

static const float kContentBorderWidth = 6.0f;
static const float kContentBorderCornerRadius = 8.0f;
static const NSUInteger kMembershipOnlyTier = 3;

@interface FlyerUpgrade ()
- (void) setupContent;
- (void) didPressBuy:(id)sender;
@end

@implementation FlyerUpgrade

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    NSAssert(false, @"must call initWithFlyer to create FlyerUpgrade");
    return nil;
}

- (id) initWithFlyer:(Flyer *)flyer
{
    self = [super initWithNibName:@"FlyerUpgrade" bundle:nil];
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
    [PogUIUtility setBorderOnView:self.contentSubView
                            width:kContentBorderWidth * 0.5f
                            color:[GameColors borderColorScanWithAlpha:1.0f]
                     cornerRadius:0.5f];
    [self.contentSubView setBackgroundColor:[GameColors gliderWhiteWithAlpha:1.0f]];
    [self.titleView setBackgroundColor:[GameColors borderColorScanWithAlpha:1.0f]];
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

- (void)viewDidUnload {
    [self setCloseCircle:nil];
    [self setTitleLabel:nil];
    [self setSecondaryTitleLabel:nil];
    [self setSpeedLevel:nil];
    [self setCapacityLevel:nil];
    [self setContentView:nil];
    [self setBuyCircle:nil];
    [self setCoinImageView:nil];
    [self setPriceLabel:nil];
    [self setImageView:nil];
    [self setContentSubView:nil];
    [self setTitleView:nil];
    [self setBuyLabel:nil];
    [super viewDidUnload];
}

#pragma mark - internal methods
- (void) didPressClose:(id)sender
{
    [[SoundManager getInstance] playClip:@"Pog_SFX_Nav_Scroll"];
    [self.navigationController popFadeOutViewControllerAnimated:YES];
}

- (void) didPressBuy:(id)sender
{
    if(![self maxUpgradeReached])
    {
        unsigned int nextTier = [_flyer nextUpgradeTier];
        BOOL isMember = [[Player getInstance] isMember];
        if (nextTier >= kMembershipOnlyTier && !isMember)
        {
            NSLog(@"Purchase membership experience");
            [[SoundManager getInstance] playClip:@"Pog_SFX_PopUP_Level2"];
            
            // Pop the modal flyerbuyconfirmation screen
            [self.navigationController popToRootViewControllerAnimated:NO];
            
            // Push the guildmembershipui screen onto the stack
            GuildMembershipUI* guildmembership = [[GuildMembershipUI alloc] initWithNibName:@"GuildMembershipUI" bundle:nil];
            GameViewController* game = [[GameManager getInstance] gameViewController];
            [game.navigationController pushFromRightViewController:guildmembership animated:YES];
        }
        else if([[Player getInstance] canAffordFlyerUpgradeTier:nextTier])
        {
            [[SoundManager getInstance] playClip:@"Pog_SFX_PopUP_Level2"];
            [[Player getInstance] buyUpgradeTier:nextTier forFlyer:_flyer];
            [self didPressClose:sender];
        }
        else
        {
            [[SoundManager getInstance] playClip:@"Pog_SFX_Select"];
            UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Not enough coins"
                                                              message:@"Go out there and trade some more"
                                                             delegate:nil
                                                    cancelButtonTitle:@"OK"
                                                    otherButtonTitles:nil];
            
            [message show];
        }
    }
}

- (BOOL)maxUpgradeReached
{
    return ([_flyer curUpgradeTier] == [[FlyerLabFactory getInstance] maxUpgradeTier]);
}

- (void) setupContent
{
    unsigned int nextTier = [_flyer nextUpgradeTier];
    BOOL isMember = [[Player getInstance] isMember];
    NSString* titleText = @"Max upgrade reached!";
    if (![self maxUpgradeReached])
    {
        if (nextTier >= kMembershipOnlyTier && !isMember)
        {
            titleText = [NSString stringWithFormat:@"Members Only Upgrade"];
            [self.buyLabel setText:@"JOIN"];
            [self.titleView setBackgroundColor:[GameColors flyerBuyTier2ColorWithAlpha:1.0]];
            [self.membershipLabel setHidden:FALSE];
        }
        else
        {
            titleText = [NSString stringWithFormat:@"Tier %d Upgrade", nextTier];
            [self.buyLabel setText:@"BUY"];
            [self.titleView setBackgroundColor:[GameColors borderColorScanWithAlpha:1.0f]];
            [self.membershipLabel setHidden:TRUE];
        }
    }
    [self.titleLabel setText:titleText];
    
    // pack info
    FlyerUpgradePack* pack = [[FlyerLabFactory getInstance] upgradeForTier:nextTier];
    NSString* speedText = [NSString stringWithFormat:@"%dx", (unsigned int)[pack speedFactor]];
    NSString* capacityText = [NSString stringWithFormat:@"%dx", (unsigned int)[pack capacityFactor]];
    [self.speedLevel setText:speedText];
    [self.capacityLevel setText:capacityText];
    [self.secondaryTitleLabel setText:[pack secondTitle]];
    
    // image
    NSString* flyerTypeName = [[FlyerTypes getInstance] sideImgForFlyerTypeAtIndex:[_flyer flyerTypeIndex]];
    NSString* imageName = [[FlyerLabFactory getInstance] sideImageForFlyerTypeNamed:flyerTypeName tier:nextTier colorIndex:[_flyer curColor]];
    UIImage* image = [[ImageManager getInstance] getImage:imageName];
    [self.imageView setImage:image];
    
    // coin image and label
    [[GameAnim getInstance] refreshImageView:[self coinImageView] withClipNamed:@"coin_shimmer"];
    [self.coinImageView startAnimating];
    NSString* priceText = [PogUIUtility commaSeparatedStringFromUnsignedInt:pack.price];
    [self.priceLabel setText:priceText];

    if(([[Player getInstance] canAffordFlyerUpgradeTier:nextTier]) &&
       (![self maxUpgradeReached]))
    {
        [self.buyLabel setTextColor:[UIColor whiteColor]];
        [self.buyLabel setAlpha:1.0f];
    }
    else
    {
        // player can't afford to buy this upgrade
        [self.buyLabel setTextColor:[UIColor lightGrayColor]];
        [self.buyLabel setAlpha:0.4f];
    }
}

@end
