//
//  NewHomeSelectItem.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/13/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NewHomeSelectItem : UIViewController
@property (weak, nonatomic) IBOutlet UIImageView *imageLeft;
@property (weak, nonatomic) IBOutlet UIImageView *imageMiddle;
@property (weak, nonatomic) IBOutlet UIImageView *imageRight;
@property (weak, nonatomic) IBOutlet UILabel *labelLeft;
@property (weak, nonatomic) IBOutlet UILabel *labelMiddle;
@property (weak, nonatomic) IBOutlet UILabel *labelRight;

- (IBAction)didPressOkLeft:(id)sender;
- (IBAction)didPressOkMiddle:(id)sender;
- (IBAction)didPressOkRight:(id)sender;
@end
