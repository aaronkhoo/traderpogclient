//
//  PostRestockConfirmScreen.h
//  traderpog
//
//  Created by Aaron Khoo on 10/17/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CircleButton.h"
#import "MyTradePost.h"

@class MyTradePost;
@interface PostRestockConfirmScreen : UIViewController
{
    MyTradePost *_post;
}
@property (nonatomic,strong) MyTradePost* post;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet CircleButton *closeCircle;
@property (weak, nonatomic) IBOutlet UIButton *restockButton;

- (IBAction)didPressRestock:(id)sender;

@end
