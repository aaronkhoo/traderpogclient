//
//  LeaderboardsScreen.h
//  traderpog
//
//  Created by Aaron Khoo on 9/24/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HttpCallbackDelegate.h"
#import "CircleButton.h"

@interface LeaderboardsScreen : UIViewController<HttpCallbackDelegate,UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *lbtable;
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;
@property (weak, nonatomic) IBOutlet CircleButton *closeCircle;

@end
