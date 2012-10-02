//
//  WheelBubble.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 6/30/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WheelBubble : UIView
{
    UIImageView* _imageView;
    UIImageView* _exclamationView;
}
@property (nonatomic,strong) UIImageView* imageView;
@property (nonatomic,strong) UIImageView* exclamationView;
@end
