//
//  ConfirmNewPost.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/14/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface ConfirmNewPost : UIViewController
- (id) initForTradePostWithCoordinate:(CLLocationCoordinate2D)coord item:(NSString*)itemId;
- (id) initForHomebaseWithCoordinate:(CLLocationCoordinate2D)coord item:(NSString*)itemId;
- (IBAction)didPressOk:(id)sender;
@end
