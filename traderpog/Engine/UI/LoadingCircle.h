//
//  LoadingCircle.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 9/14/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoadingCircle : UIView

- (id)initWithFrame:(CGRect)frame color:(UIColor*)color borderColor:(UIColor*)borderColor decalImage:(UIImage*)decalImage rotateIcon:(UIImage*)rotateIcon;
- (void) update:(NSTimeInterval)elapsed;
- (void) startAnim;
- (void) stopAnim;
@end
