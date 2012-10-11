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
#import "Player.h"
#import "Player+Shop.h"
#import <QuartzCore/QuartzCore.h>

static const float kContentBorderWidth = 6.0f;
static const float kContentBorderCornerRadius = 8.0f;
static const float kOptionBorderWidth = 4.0f;
static const float kOptionBotHeight = 0.2f;

enum kColorOptions
{
    kColorOptionOriginal = 0,
    kColorOption1,
    kColorOption2,
    kColorOption3,
    
    kColorOptionNum
};

@interface FlyerCustomize ()
{
    unsigned int _curSelection;
}
@property (nonatomic) unsigned int curSelection;
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
    
    // colors and borders
    [PogUIUtility setBorderOnView:self.contentView
                            width:kContentBorderWidth
                            color:[GameColors borderColorScanWithAlpha:1.0f]
                     cornerRadius:kContentBorderCornerRadius];
    [PogUIUtility setBorderOnView:self.contentSubView
                            width:kContentBorderWidth * 0.5f
                            color:[GameColors borderColorScanWithAlpha:1.0f]
                     cornerRadius:0.5f];
    [self.contentSubView setBackgroundColor:[GameColors gliderWhiteWithAlpha:1.0f]];
    [self.titleView setBackgroundColor:[GameColors borderColorScanWithAlpha:1.0f]];
    [self.contentView setBackgroundColor:[GameColors bubbleColorFlyersWithAlpha:1.0f]];
    [self.closeCircle setBorderColor:[GameColors borderColorScanWithAlpha:1.0f]];
    [self.closeCircle setButtonTarget:self action:@selector(didPressClose:)];
    [self.buyCircle setBorderColor:[GameColors borderColorScanWithAlpha:1.0f]];
    [self.buyCircle setButtonTarget:self action:@selector(didPressBuy:)];
    
    // setup stamps initial state
    [self.origStamp setHidden:YES];
    [self.stamp1 setHidden:YES];
    [self.stamp2 setHidden:YES];
    [self.stamp3 setHidden:YES];
    [PogUIUtility setBorderOnView:self.optionOriginal
                            width:kOptionBorderWidth
                            color:[GameColors borderColorScanWithAlpha:1.0f]
                     cornerRadius:kContentBorderCornerRadius];
    [PogUIUtility setBorderOnView:self.option1
                            width:kOptionBorderWidth
                            color:[GameColors borderColorScanWithAlpha:1.0f]
                     cornerRadius:kContentBorderCornerRadius];
    [PogUIUtility setBorderOnView:self.option2
                            width:kOptionBorderWidth
                            color:[GameColors borderColorScanWithAlpha:1.0f]
                     cornerRadius:kContentBorderCornerRadius];
    [PogUIUtility setBorderOnView:self.option3
                            width:kOptionBorderWidth
                            color:[GameColors borderColorScanWithAlpha:1.0f]
                     cornerRadius:kContentBorderCornerRadius];
    
    // bottom bar on each of the option boxes
    [self.origBar setBackgroundColor:[GameColors borderColorScanWithAlpha:1.0f]];
    [self.bar1 setBackgroundColor:[GameColors borderColorScanWithAlpha:1.0f]];
    [self.bar2 setBackgroundColor:[GameColors borderColorScanWithAlpha:1.0f]];
    [self.bar3 setBackgroundColor:[GameColors borderColorScanWithAlpha:1.0f]];
    
    [self setupContent];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
    [self setOrigBar:nil];
    [self setBar1:nil];
    [self setBar2:nil];
    [self setBar3:nil];
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
    [self setOrigStamp:nil];
    [self setStamp1:nil];
    [self setStamp2:nil];
    [self setStamp3:nil];
    [self setTitleView:nil];
    [self setContentSubView:nil];
    [self setBuyLabel:nil];
    [super viewDidUnload];
}

#pragma mark - internal methods
- (void) didPressClose:(id)sender
{
    [self.navigationController popFadeOutViewControllerAnimated:YES];
}

- (void) didPressBuy:(id)sender
{
    if(_curSelection != [_flyer curColor])
    {
        if([[Player getInstance] canAffordFlyerColor])
        {
            [[Player getInstance] buyColorCustomization:_curSelection forFlyer:_flyer];
            [self didPressClose:sender];
        }
        else
        {
            UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Not enough coins"
                                                              message:@"Go out there and trade some more"
                                                             delegate:nil
                                                    cancelButtonTitle:@"OK"
                                                    otherButtonTitles:nil];
            
            [message show];
        }
    }
}

- (unsigned int) curSelection
{
    return _curSelection;
}

- (void) setCurSelection:(unsigned int)newSelection
{
    [self.origStamp setHidden:YES];
    [self.stamp1 setHidden:YES];
    [self.stamp2 setHidden:YES];
    [self.stamp3 setHidden:YES];
    
    // stamp selection
    switch(newSelection)
    {
        case kColorOption1:
            [self.stamp1 setHidden:NO];
            break;
            
        case kColorOption2:
            [self.stamp2 setHidden:NO];
            break;
            
        case kColorOption3:
            [self.stamp3 setHidden:NO];
            break;
            
        case kColorOptionOriginal:
        default:
            [self.origStamp setHidden:NO];
            break;
    }
    
    // image
    NSString* imageName = [[FlyerLabFactory getInstance] sideImageForFlyerTypeNamed:@"flyer_glider" tier:[_flyer curUpgradeTier] colorIndex:newSelection];
    UIImage* image = [[ImageManager getInstance] getImage:imageName];
    [self.imageView setImage:image];
    
    // update current selection
    _curSelection = newSelection;
}

- (void) setupContent
{
    // selection
    [self setCurSelection:[_flyer curColor]];
    
    // coin image and label
    [[GameAnim getInstance] refreshImageView:[self coinImageView] withClipNamed:@"coin_shimmer"];
    [self.coinImageView startAnimating];
    
    // price
    NSString* priceText = [PogUIUtility commaSeparatedStringFromUnsignedInt:[[FlyerLabFactory getInstance] priceForColorCustomization]];
    [self.priceLabel setText:priceText];
    
    if([[Player getInstance] canAffordFlyerColor])
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


- (IBAction)didPressOptionOriginal:(id)sender
{
    [self setCurSelection:0];
}

- (IBAction)didPressOption1:(id)sender
{
    [self setCurSelection:1];
}


- (IBAction)didPressOption2:(id)sender
{
    [self setCurSelection:2];
}

- (IBAction)didPressOption3:(id)sender
{
    [self setCurSelection:3];
}
@end
