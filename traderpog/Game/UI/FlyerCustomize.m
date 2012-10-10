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
#import <QuartzCore/QuartzCore.h>

static const float kContentBorderWidth = 6.0f;
static const float kContentBorderCornerRadius = 8.0f;
static const float kOptionBorderWidth = 4.0f;

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
    [PogUIUtility setBorderOnView:self.contentView
                            width:kContentBorderWidth
                            color:[GameColors borderColorScanWithAlpha:1.0f]
                     cornerRadius:kContentBorderCornerRadius];
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
    [self setOrigStamp:nil];
    [self setStamp1:nil];
    [self setStamp2:nil];
    [self setStamp3:nil];
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
        [_flyer applyColor:_curSelection];
    }
    [self didPressClose:sender];
}

- (unsigned int) curSelection
{
    return _curSelection;
}

- (void) setCurSelection:(unsigned int)newSelection
{
    UIColor* highlight = [GameColors borderColorPostsWithAlpha:1.0f];
    UIColor* normal = [GameColors borderColorScanWithAlpha:1.0f];
    [self.optionOriginal.layer setBorderColor:normal.CGColor];
    [self.option1.layer setBorderColor:normal.CGColor];
    [self.option2.layer setBorderColor:normal.CGColor];
    [self.option3.layer setBorderColor:normal.CGColor];
    
    // highlight selection
    switch(newSelection)
    {
        case kColorOption1:
            [self.option1.layer setBorderColor:highlight.CGColor];
            break;
            
        case kColorOption2:
            [self.option2.layer setBorderColor:highlight.CGColor];
            break;
            
        case kColorOption3:
            [self.option3.layer setBorderColor:highlight.CGColor];
            break;
            
        case kColorOptionOriginal:
        default:
            [self.optionOriginal.layer setBorderColor:highlight.CGColor];
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
    switch([_flyer curColor])
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
    [self setCurSelection:[_flyer curColor]];
    
    // coin image and label
    [[GameAnim getInstance] refreshImageView:[self coinImageView] withClipNamed:@"coin_shimmer"];
    [self.coinImageView startAnimating];
    
    // price
    NSString* priceText = [PogUIUtility commaSeparatedStringFromUnsignedInt:[[FlyerLabFactory getInstance] priceForColorCustomization]];
    [self.priceLabel setText:priceText];
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
