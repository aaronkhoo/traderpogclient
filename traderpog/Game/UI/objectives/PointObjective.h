//
//  PointObjective.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/21/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewReuseDelegate.h"

extern NSString* const kPointObjectiveViewReuseIdentifier;

@class GameObjective;
@interface PointObjective : UIView<ViewReuseDelegate>
@property (strong, nonatomic) IBOutlet UIView *nibView;
@property (weak, nonatomic) IBOutlet UIView *nibContentView;
@property (weak, nonatomic) IBOutlet UILabel *descLabel;

- (id) initWithGameObjective:(GameObjective*)objective;
@end
