//
//  GuildMembershipUI.m
//  traderpog
//
//  Created by Aaron Khoo on 10/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "UINavigationController+Pog.h"
#import "GuildMembershipUI.h"
#import "MBProgressHUD.h"
#import "ProductManager.h"
#import "CircleButton.h"
#import "GameColors.h"
#import "PogUIUtility.h"
#import "Player.h"

@interface GuildMembershipUI ()
- (void)didPressClose:(id)sender;
@end

@implementation GuildMembershipUI
@synthesize testText;
@synthesize buyButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
    }
    return self;
}

- (void) dealloc
{
    NSLog(@"GuildMembershipUI dealloc");
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.closeCircle setBorderColor:[GameColors borderColorScanWithAlpha:1.0f]];
    [self.closeCircle setButtonTarget:self action:@selector(didPressClose:)];
    [self.productContainer setHidden:YES];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleProductsFetched:)
                                                 name:kProductManagerProductsFetchedNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleProductsFetchFailed:)
                                                 name:kProductManagerFetchFailedNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleSKTransactionSucceeded:)
                                                 name:kProductManagerTransactionSucceededNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleSKTransactionFailed:)
                                                 name:kProductManagerTransactionFailedNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleSKTransactionCanceled:)
                                                 name:kProductManagerTransactionCanceledNotification
                                               object:nil];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"Retrieving products";
    
    if ([[ProductManager getInstance] needsRefresh])
    {
        [[ProductManager getInstance] requestProductData];   
    }
    else
    {
        [self displayProducts];
    }
}

- (void)didPressClose:(id)sender
{
    [self.navigationController popToRightViewControllerAnimated:YES];
}

- (IBAction)didPressBuy:(id)sender
{
    SKProduct* product = [[[ProductManager getInstance] productsArray] objectAtIndex:0];
    [[ProductManager getInstance] purchaseMembershipByProductID:[product productIdentifier]];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"Purchasing membership";
}

#pragma mark - private functions

- (void)refreshForMember
{
    if([[Player getInstance] isMember])
    {
        // already a member
        NSString* joinedTxt = @"JOINED";
        [self.priceLabel1 setText:joinedTxt];
        [self.priceLabelLimited setText:joinedTxt];
        [self.purchaseButtonImageView setImage:[UIImage imageNamed:@"icon_member_joined.png"]];
        [self.buyButton setHidden:YES];
        [self.limitedOfferView setHidden:YES];
    }
}
- (void)displayProducts
{
    SKProduct* product = [[[ProductManager getInstance] productsArray] objectAtIndex:0];
    [self.productLabel1 setText:product.localizedTitle];
    [self.productContainer setHidden:NO];

    if([[Player getInstance] isMember])
    {
        // already a member
        [self refreshForMember];
    }
    else
    {
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
        [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [numberFormatter setLocale:product.priceLocale];
        NSString *formattedString = [numberFormatter stringFromNumber:product.price];
        [self.priceLabel1 setText:formattedString];
        [self.priceLabelLimited setText:formattedString];
        [self.purchaseButtonImageView setImage:[UIImage imageNamed:@"icon_member_join_frame.png"]];
        if ([[ProductManager getInstance] canMakePurchases])
        {
            [buyButton setHidden:FALSE];
            [self.limitedOfferView setHidden:NO];
        }
        else
        {
            NSLog(@"Current account cannot make purchases");
        }        
    }
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

#pragma mark - product manager

- (void) handleProductsFetched:(NSNotification *)note
{
    [self displayProducts];
}

- (void) handleProductsFetchFailed:(NSNotification*) note
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void) handleSKTransactionCanceled:(NSNotification *)note
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void) handleSKTransactionFailed:(NSNotification *)note
{  
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Purchase failed"
                                                    message:@"Try again later"
                                                   delegate:self
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil];
    [alert show];
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void) handleSKTransactionSucceeded:(NSNotification *)note
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Purchase Completed"
                                                    message:nil
                                                   delegate:self
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil];
    [alert show];
    [self refreshForMember];
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setCloseCircle:nil];
    [self setProductLabel1:nil];
    [self setProductContainer:nil];
    [self setPriceLabel1:nil];
    [self setPriceLabelLimited:nil];
    [self setPurchaseButtonImageView:nil];
    [self setLimitedOfferView:nil];
    [super viewDidUnload];
}
@end
