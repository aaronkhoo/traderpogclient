//
//  LoadingCircle.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 9/14/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^LoadingCircleDismissCompletion)(void);

@interface LoadingCircle : UIView

// init
- (id)initWithFrame:(CGRect)frame color:(UIColor*)color borderColor:(UIColor*)borderColor decalImage:(UIImage*)decalImage rotateIcon:(UIImage*)rotateIcon visibleFraction:(float)visibleFraction;

// anim
- (void) update:(NSTimeInterval)elapsed;
- (void) startAnim;
- (void) stopAnim;
- (void) showAnimated:(BOOL)animated afterDelay:(float)delay;
- (void) hideAnimated:(BOOL)animated completion:(LoadingCircleDismissCompletion)completion;
@end
