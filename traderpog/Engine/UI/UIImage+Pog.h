//
//  UIImage+Pog.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/6/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Pog)

// reference: http://coffeeshopped.com/2010/09/iphone-how-to-dynamically-color-a-uiimage
+ (UIImage*) imageNamed:(NSString*)name withColor:(UIColor*)color;
@end
