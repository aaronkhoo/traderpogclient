//
//  FlyerGo.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 11/6/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CircleButton.h"

@class TradePost;
@class FlyerGoCell;
@interface FlyerGo : UIViewController<UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet CircleButton *closeCircle;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet FlyerGoCell *goCell;
- (id) initWithPost:(TradePost*)post;
@end
