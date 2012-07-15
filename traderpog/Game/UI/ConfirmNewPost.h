//
//  ConfirmNewPost.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/14/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@class TradeItemType;
@interface ConfirmNewPost : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *contentLabel;
- (id) initForTradePostWithCoordinate:(CLLocationCoordinate2D)coord itemType:(TradeItemType*)itemType;
- (id) initForHomebaseWithCoordinate:(CLLocationCoordinate2D)coord itemType:(TradeItemType*)itemType;
- (IBAction)didPressOk:(id)sender;
@end
