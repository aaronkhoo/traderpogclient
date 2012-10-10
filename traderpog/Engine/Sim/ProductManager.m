//
//  ProductManager.m
//  traderpog
//
//  Created by Aaron Khoo on 10/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//


#import "ProductManager.h"
#import "Reachability.h"

NSString* const GUILD_MEMBERSHIP = @"com.geolopigs.traderpog.membership";

@interface ProductManager (PrivateMethods)
- (void) deliverContentForProductIdentifier:(NSString*)productId;
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
    }
    return self;
}

- (void) dealloc
{
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    self.productsArray = nil;
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
        // only request if no previous request succeeded and no ongoing request
        if((nil == _productsRequest) && (0 == [self getNumProducts]))
        {
            NSSet *productIdentifiers = [NSSet setWithObjects:
                                         GUILD_MEMBERSHIP,
                                         nil];
            _productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
            _productsRequest.delegate = self;
            [_productsRequest start];
            
            // we will release the request object in the delegate callback
        }
    }
    
    return isInternetReachable;
}

- (void) purchaseUpgradeByProductID:(NSString *)productID
{
	SKProduct* productCurrent = [_productLookup objectForKey:productID];
    if(productCurrent)
    {
        SKPayment *payment = [SKPayment paymentWithProduct:productCurrent];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
}

- (void) deliverContentForProductIdentifier:(NSString *)productId
{
    if([productId isEqualToString:GUILD_MEMBERSHIP])
    {
        //[[PlayerInventory getInstance] addPogcoins:POGCOINS_STARTERPACK_AMOUNT];
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
- (void)finishTransaction:(SKPaymentTransaction *)transaction wasSuccessful:(BOOL)wasSuccessful
{
    // remove the transaction from the payment queue.
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:transaction, @"transaction" , nil];
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


//
// called when the transaction was successful
//
- (void)completeTransaction:(SKPaymentTransaction *)transaction
{
    // TODO: record receipt
    //[[PlayerInventory getInstance] recordReceiptForTransaction:transaction];
    
    // deliver product to PlayerInventory
    NSString* productId = [[transaction payment] productIdentifier];
    [self deliverContentForProductIdentifier:productId];
    
    // finish the transaction
    [self finishTransaction:transaction wasSuccessful:YES];
}

//
// called when a transaction has been restored and and successfully completed
//
- (void)restoreTransaction:(SKPaymentTransaction *)transaction
{
    // TODO
    //[[PlayerInventory getInstance] recordReceiptForTransaction:transaction.originalTransaction];
    NSString* productId = [[[transaction originalTransaction] payment] productIdentifier];
    [self deliverContentForProductIdentifier:productId];
    [self finishTransaction:transaction wasSuccessful:YES];
}

//
// called when a transaction has failed
//
- (void)failedTransaction:(SKPaymentTransaction *)transaction
{
    if (transaction.error.code != SKErrorPaymentCancelled)
    {
        // error!
        [self finishTransaction:transaction wasSuccessful:NO];
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
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
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
}

- (void) request:(SKRequest *)request didFailWithError:(NSError *)error
{
    // release request
    _productsRequest = nil;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kProductManagerFetchFailedNotification object:self];
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
