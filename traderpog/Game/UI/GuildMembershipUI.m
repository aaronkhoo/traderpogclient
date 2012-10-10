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

@interface GuildMembershipUI ()

@end

@implementation GuildMembershipUI
@synthesize testText;
@synthesize buyButton;

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
	// Do any additional setup after loading the view.
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

- (IBAction)didPressClose:(id)sender
{
    [self.navigationController popToRightViewControllerAnimated:YES];
}

#pragma mark - private functions

- (void)displayProducts
{
    SKProduct* product = [[[ProductManager getInstance] productsArray] objectAtIndex:0];
    testText.text = [NSString stringWithFormat:@"%@\n%@\n%@", product.localizedTitle, product.localizedDescription, product.price];
    [buyButton setHidden:FALSE];
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

#pragma mark - product manager

- (void) handleProductsFetched:(NSNotification *)note
{
    [self displayProducts];
}

- (void) handleProductsFetchFailed:(NSNotification*) note
{
}

- (void) handleSKTransactionCanceled:(NSNotification *)note
{
}

- (void) handleSKTransactionFailed:(NSNotification *)note
{  
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Purchase failed"
                                                    message:@"Try again later"
                                                   delegate:self
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void) handleSKTransactionSucceeded:(NSNotification *)note
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Purchase Completed"
                                                    message:nil
                                                   delegate:self
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
