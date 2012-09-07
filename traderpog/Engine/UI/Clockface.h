//
//  Clockface.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 9/6/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AnimDelegate.h"

@interface Clockface : UIView<AnimDelegate>
- (void) startAnimating;
- (void) stopAnimating;
@end
