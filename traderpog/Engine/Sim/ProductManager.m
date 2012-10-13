//
//  ProductManager.m
//  traderpog
//
//  Created by Aaron Khoo on 10/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "Player.h"
#import "PogUIUtility.h"
#import "ProductManager.h"
#import "Reachability.h"

NSString* const GUILD_MEMBERSHIP = @"com.geolopigs.traderpog.membership";

@interface ProductManager (PrivateMethods)
- (void) deliverContentForProductIdentifier:(NSString*)productId receipt:(NSString*)receipt;
@end

@implementation ProductManager
@synthesize productsArray = _productsArray;
@synthesize productLookup = _productLookup;

- (id) init
{
    self = [super init];
    if(self)
    {
        // register myself as an observer upon startup
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        
        _productsArray = nil;
        _productLookup = [NSMutableDictionary dictionary];
        _currentTransaction = nil;
        
        // Setting up callback for membership update
        [[Player getInstance] setMemberDelegate:self];
    }
    return self;
}

- (void) dealloc
{
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    self.productsArray = nil;
}

- (BOOL) needsRefresh
{
    // only request if no previous request succeeded and no ongoing request
    return ((nil == _productsRequest) && (0 == [self getNumProducts]));
}

#pragma mark - transaction methods

- (BOOL)requestProductData
{
    BOOL isInternetReachable = YES;
    Reachability* internetReach = [Reachability reachabilityForInternetConnection];
    NetworkStatus status = [internetReach currentReachabilityStatus];
    if(NotReachable == status)
    {
        isInternetReachable = NO;
    }
    
    if(isInternetReachable)
    {
        NSSet *productIdentifiers = [NSSet setWithObjects:
                                     GUILD_MEMBERSHIP,
                                     nil];
        _productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
        _productsRequest.delegate = self;
        [_productsRequest start];
        NSLog(@"ProductManager: Requesting products");
        
        // we will release the request object in the delegate callback
    }
    
    return isInternetReachable;
}

- (BOOL) purchaseMembershipByProductID:(NSString *)productID
{
    BOOL success = FALSE;
    // Don't launch another purchase if one is already in flight
    if (!_currentTransaction)
    {
     	SKProduct* productCurrent = [_productLookup objectForKey:productID];
        if(productCurrent)
        {
            SKPayment *payment = [SKPayment paymentWithProduct:productCurrent];
            [[SKPaymentQueue defaultQueue] addPayment:payment];
            success = TRUE;
        }
    }
    return success;
}

- (void) deliverContentForProductIdentifier:(NSString *)productId receipt:(NSString*)receipt
{
    if([productId isEqualToString:GUILD_MEMBERSHIP])
    {
        [[Player getInstance] updateMembershipInfo:receipt];
    }
}

#pragma mark - accessors

//
// call this before making a purchase
//
- (BOOL)canMakePurchases
{
    return [SKPaymentQueue canMakePayments];
}

- (unsigned int) getNumProducts
{
    unsigned int result = 0;
    if([self productsArray])
    {
        result = [[self productsArray] count];
    }
    return result;
}

#pragma mark - transaction methods

//
// removes the transaction from the queue and posts a notification with the transaction result
//
- (void)finishTransaction:(BOOL)wasSuccessful
{    
    if (_currentTransaction)
    {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:_currentTransaction, @"transaction" , nil];
        if (wasSuccessful)
        {
            // send out a notification that we’ve finished the transaction
            [[NSNotificationCenter defaultCenter] postNotificationName:kProductManagerTransactionSucceededNotification object:self userInfo:userInfo];
        }
        else
        {
            // send out a notification for the failed transaction
            [[NSNotificationCenter defaultCenter] postNotificationName:kProductManagerTransactionFailedNotification object:self userInfo:userInfo];
        }
    }
    
    // Clear the current transaction
    _currentTransaction = nil;
}


//
// called when the transaction was successful
//
- (void)completeTransaction:(SKPaymentTransaction *)transaction
{
    // generate base64 encoded version of receipt
    NSData* rawReceipt = [transaction transactionReceipt];
    NSString* base64Receipt = [PogUIUtility base64forData:rawReceipt];
    NSLog(@"Complete transaction receipt: %@", base64Receipt);
    
    NSString* productId = [[transaction payment] productIdentifier];
    [self deliverContentForProductIdentifier:productId receipt:base64Receipt];
    
    if (_currentTransaction)
    {
        NSLog(@"ERROR! Existing transaction is being overriden!");
    }
    else
    {
        _currentTransaction = transaction;
    }
    
    // remove the transaction from the payment queue.
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

//
// called when a transaction has been restored and and successfully completed
//
- (void)restoreTransaction:(SKPaymentTransaction *)transaction
{
    // generate base64 encoded version of receipt
    NSData* rawReceipt = [transaction transactionReceipt];
    NSString* base64Receipt = [PogUIUtility base64forData:rawReceipt];
    NSLog(@"Restore transaction receipt: %@", base64Receipt);
    
    NSString* productId = [[[transaction originalTransaction] payment] productIdentifier];
    [self deliverContentForProductIdentifier:productId receipt:base64Receipt];
    
    if (_currentTransaction)
    {
        NSLog(@"ERROR! Existing transaction is being overriden!");
    }
    else
    {
        _currentTransaction = transaction;
    }
    
    // remove the transaction from the payment queue.
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

//
// called when a transaction has failed
//
- (void)failedTransaction:(SKPaymentTransaction *)transaction
{
    if (transaction.error.code != SKErrorPaymentCancelled)
    {
        if (_currentTransaction)
        {
            NSLog(@"ERROR! Existing transaction is being overriden!");
        }
        else
        {
            _currentTransaction = transaction;
        }
        
        // remove the transaction from the payment queue.
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        
        // error!
        [self finishTransaction:NO];
    }
    else
    {
        // user just canceled
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        
        // send out a notification for the canceled transaction
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:transaction, @"transaction" , nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:kProductManagerTransactionCanceledNotification object:self userInfo:userInfo];
    }
}

#pragma mark - SKPaymentTransactionObserver methods

//
// called when the transaction status is updated
//
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                NSLog(@"SKPaymentTransactionStatePurchased received");
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                NSLog(@"SKPaymentTransactionStateFailed received");
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                NSLog(@"SKPaymentTransactionStateRestored received");
                [self restoreTransaction:transaction];
                break;
            case SKPaymentTransactionStatePurchasing:
                NSLog(@"SKPaymentTransactionStatePurchasing received");
                break;
            default:
                // do nothing
                break;
        }
    }
}

#pragma mark -
#pragma mark SKProductsRequestDelegate methods

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    unsigned int numValidProducts = 0;
    unsigned int numInvalidProducts = 0;
    self.productsArray = [NSArray arrayWithArray:[response products]];
    [_productLookup removeAllObjects];
    for(SKProduct* cur in [self productsArray])
    {
        [_productLookup setObject:cur forKey:cur.productIdentifier];
        ++numValidProducts;
    }
    
	// Log invalid IDs
    for (NSString *invalidProductId in response.invalidProductIdentifiers)
    {
        NSLog(@"Invalid product id: %@" , invalidProductId);
        ++numInvalidProducts;
    }
    
    // finally release the reqest we alloc/init’ed in requestProductData
    _productsRequest = nil;
    
    if((numValidProducts == 0) && (0 < numInvalidProducts))
    {
        // if all products are invalid, treat it as a failed fetch
        [[NSNotificationCenter defaultCenter] postNotificationName:kProductManagerFetchFailedNotification object:self];
    }
    else
    {
        // Tell anyone who cares that we're done loading
        [[NSNotificationCenter defaultCenter] postNotificationName:kProductManagerProductsFetchedNotification object:self];
    }
    
    NSLog(@"ProductManager: %d valid products received and %d invalid products received", numValidProducts, numInvalidProducts);
}

- (void) request:(SKRequest *)request didFailWithError:(NSError *)error
{
    // release request
    _productsRequest = nil;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kProductManagerFetchFailedNotification object:self];
}

#pragma mark - HttpCallbackDelegate
- (void) didCompleteHttpCallback:(NSString*)callName, BOOL success
{
    if ([callName compare:kPlayer_UpdateMember] == NSOrderedSame)
    {
        // finish the transaction
        [self finishTransaction:YES];
    }
    else
    {
        NSLog(@"Unknown callback to GuildMembershipUI occurred: %@", callName);
    }
}

#pragma mark - Singleton
static ProductManager* singleton = nil;
+ (ProductManager*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
			singleton = [[ProductManager alloc] init];
		}
	}
	return singleton;
}

+ (void) destroyInstance
{
	@synchronized(self)
	{
		singleton = nil;
	}
}

@end
