//
//  FlyerInventory.h
//  traderpog
//
//  Created by Aaron Khoo on 9/2/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

@interface FlyerInventory : NSObject<NSCoding>
{
    // inventory
    NSString* _itemId;
    unsigned int _numItems;
    float _costBasis;
    CLLocationDistance _metersTraveled;
    
    // escrow
    NSString* _orderItemId;
    unsigned int _orderNumItems;
    unsigned int _orderPrice;
}
@property (nonatomic,strong) NSString* itemId;
@property (nonatomic) unsigned int numItems;
@property (nonatomic) float costBasis;
@property (nonatomic,strong) NSString* orderItemId;
@property (nonatomic) unsigned int orderNumItems;
@property (nonatomic) unsigned int orderPrice;
@property (nonatomic) CLLocationDistance metersTraveled;

- (id) initWithDictionary:(NSDictionary*)dict;

// trade
- (void) addItemId:(NSString*)itemId num:(unsigned int)num price:(unsigned int)price;
- (void) orderItemId:(NSString*)itemId num:(unsigned int)num price:(unsigned int)price;
- (void) commitOutstandingOrder;
- (void) unloadAllItems;
- (void) incrementTravelDistance:(CLLocationDistance) routeDist;
- (void) resetDistanceTraveled;
- (void) updateFlyerInventoryOnServer:(NSString*)userFlyerId;

@end
