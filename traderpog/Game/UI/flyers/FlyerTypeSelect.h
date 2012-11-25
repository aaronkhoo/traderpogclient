//
//  FlyerTypeSelect.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 11/25/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CircleButton.h"

@class FlyerTypeSelectCell;
@interface FlyerTypeSelect : UIViewController<UITableViewDelegate, UITableViewDataSource>
@property (strong, nonatomic) IBOutlet FlyerTypeSelectCell* flyerCell;
@property (weak, nonatomic) IBOutlet UITableView* tableView;
@property (weak, nonatomic) IBOutlet CircleButton* closeCircle;
@end
