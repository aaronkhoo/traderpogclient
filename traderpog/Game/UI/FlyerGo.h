//
//  FlyerGo.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 11/6/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CircleButton.h"

@interface FlyerGo : UIViewController<UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet CircleButton *closeCircle;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
