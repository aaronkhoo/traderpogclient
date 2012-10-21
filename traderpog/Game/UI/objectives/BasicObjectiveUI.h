//
//  BasicObjectiveUI.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/21/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CircleButton.h"

@class GameObjective;
@interface BasicObjectiveUI : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *descLabel;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet CircleButton *okCircle;

- (id) initWithGameObjective:(GameObjective*)gameObjective;

@end
