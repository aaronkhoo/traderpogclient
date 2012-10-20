//
//  FlyerBuyConfirmScreen.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/18/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "UINavigationController+Pog.h"
#import "FlyerBuyConfirmScreen.h"
#import "FlyerLabFactory.h"
#import "FlyerType.h"
#import "GameManager.h"
#import "GuildMembershipUI.h"
#import "GameColors.h"
#import "ImageManager.h"
#import "Player.h"
#import "Player+Shop.h"
#import "PogUIUtility.h"
#import "TradePostMgr.h"
#import "TradePost.h"
#import "Flyer.h"
#import "FlyerMgr.h"
#import "FlyerTypes.h"
#import "MBProgressHUD.h"

static const float kContentBorderWidth = 6.0f;
static const float kContentBorderCornerRadius = 8.0f;
static const NSUInteger kMembershipTier = 4;

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
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
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
    
    if ([_flyerType tier] >= kMembershipTier && ![[Player getInstance] isMember])
    {
        // flyer descriptions
        NSString* flyerDesc = [NSString stringWithFormat:@"%@\n\n%@", [_flyerType desc], @"Trader Guild members only!"];
        [self.flyerDescLabel setText:flyerDesc];
        [self.flyerDescLabel setAdjustsFontSizeToFitWidth:TRUE];
        
        [self.titleView setBackgroundColor:[GameColors flyerBuyTier2ColorScanWithAlpha:1.0]];
        [self.buyButtonLabel setText:@"JOIN"];
        [self.membershipLabel setHidden:FALSE];
    }
    else
    {
        // flyer descriptions
        [self.flyerDescLabel setText:[_flyerType desc]];
        [self.titleView setBackgroundColor:[GameColors flyerBuyTier1ColorScanWithAlpha:1.0]];
        [self.buyButtonLabel setText:@"BUY"];
        
        if([[Player getInstance] canAffordFlyerType:_flyerType])
        {
            [self.buyButtonLabel setTextColor:[UIColor whiteColor]];
            [self.buyButtonLabel setAlpha:1.0f];
        }
        else
        {
            // player can't afford to buy this upgrade
            [self.buyButtonLabel setTextColor:[UIColor lightGrayColor]];
            [self.buyButtonLabel setAlpha:0.4f];
        }
    }
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
    if ([_flyerType tier] >= kMembershipTier && ![[Player getInstance] isMember])
    {
        NSLog(@"Purchase membership experience");
        
        // Pop the modal flyerbuyconfirmation screen
        [self.navigationController popToRootViewControllerAnimated:NO];
     
        // Push the guildmembershipui screen onto the stack
        GuildMembershipUI* guildmembership = [[GuildMembershipUI alloc] initWithNibName:@"GuildMembershipUI" bundle:nil];
        GameViewController* game = [[GameManager getInstance] gameViewController];
        [game.navigationController pushFromRightViewController:guildmembership animated:YES];
    }
    else if([[Player getInstance] canAffordFlyerType:_flyerType])
    {
        NSLog(@"Purchase flyer experience");

        // Pop the modal flyerbuyconfirmation screen
        [self.navigationController popToRootViewControllerAnimated:NO];

        GameViewController* game = [[GameManager getInstance] gameViewController];
        TradePost* newFlyerPost = [[TradePostMgr getInstance] getFirstMyTradePost];
        if([newFlyerPost flyerAtPost])
        {
            // there's already a flyer at home, generate an npc post nearby
            CLLocationCoordinate2D newCoord = [newFlyerPost coord];
            CLLocation* newLoc = [game.mapControl availableLocationNearCoord:newCoord visibleOnly:YES];
            if(newLoc)
            {
                newCoord = [newLoc coordinate];
            }
            
            newFlyerPost = [[TradePostMgr getInstance] newNPCTradePostAtCoord:newCoord bucks:0];
            [game.mapControl addAnnotationForTradePost:newFlyerPost isScan:YES];
        }

        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:game.view animated:YES];
        hud.labelText = @"Purchasing Flyer";
     
        NSInteger flyerTypeIndex = [[FlyerTypes getInstance] getFlyerIndexById:[_flyerType flyerId]];
        [[FlyerMgr getInstance] newPlayerFlyerAtTradePost:newFlyerPost purchasedFlyerTypeIndex:flyerTypeIndex];
    }
}

@end
