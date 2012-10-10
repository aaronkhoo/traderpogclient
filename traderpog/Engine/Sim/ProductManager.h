//
//  ProductManager.h
//  traderpog
//
//  Created by Aaron Khoo on 10/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

// Notifications for any observers that specific events have occurred
#define kProductManagerProductsFetchedNotification @"kProductManagerProductsFetchedNotification"
#define kProductManagerFetchFailedNotification @"kProductManagerFetchFailedNotification"
#define kProductManagerTransactionFailedNotification @"kProductManagerTransactionFailedNotification"
#define kProductManagerTransactionCanceledNotification @"kProductManagerTransactionCanceledNotification"
#define kProductManagerTransactionSucceededNotification @"kProductManagerTransactionSucceededNotification"

@interface ProductManager : NSObject<SKProductsRequestDelegate, SKPaymentTransactionObserver>
{
    NSArray* _productsArray;
    NSMutableDictionary* _productLookup;
    SKProductsRequest* _productsRequest;
}
@property (nonatomic,retain) NSArray* productsArray;
@property (nonatomic,retain) NSMutableDictionary* productLookup;

// transaction methods
- (BOOL)requestProductData;
- (void) purchaseUpgradeByProductID:(NSString *)productID;

// accessors
- (BOOL) canMakePurchases;
- (unsigned int) getNumProducts;

// singleton
+(ProductManager*) getInstance;
+(void) destroyInstance;


@end
