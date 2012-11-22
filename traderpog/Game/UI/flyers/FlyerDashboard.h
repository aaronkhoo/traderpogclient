//
//  FlyerDashboard.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 11/18/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CircleButton.h"

@class FlyerDashboardCell;
@interface FlyerDashboard : UIViewController<UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet CircleButton *closeCircle;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet FlyerDashboardCell *flyerCell;

@end
