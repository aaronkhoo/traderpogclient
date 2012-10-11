//
//  PostAccelView.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/11/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewReuseDelegate.h"

extern NSString* const kPostAccelViewReuseIdentifier;

@class CircleButton;
@class Flyer;
@interface PostAccelView : UIView<ViewReuseDelegate>
@property (strong, nonatomic) IBOutlet UIView *nibView;
@property (weak, nonatomic) IBOutlet UIView *nibContentView;
@property (weak, nonatomic) IBOutlet CircleButton *closeCircle;
@property (weak, nonatomic) IBOutlet CircleButton *buyCircle;
@property (weak, nonatomic) IBOutlet UILabel *okLabel;
@property (weak, nonatomic) IBOutlet UIImageView *coinImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *costLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

- (void) addButtonTarget:(id)target;
- (void) refreshViewForFlyer:(Flyer*)flyer;
@end
