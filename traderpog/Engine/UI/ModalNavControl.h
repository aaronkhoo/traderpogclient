//
//  ModalNavControl.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/13/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ModalNavDelegate.h"

@interface ModalNavControl : UIViewController<UINavigationControllerDelegate>
@property (nonatomic,weak) id<ModalNavDelegate> delegate;
@property (nonatomic,strong) UINavigationController* navController;
@end
