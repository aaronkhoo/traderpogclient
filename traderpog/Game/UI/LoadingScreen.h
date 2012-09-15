//
//  LoadingScreen.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoadingScreen : UIViewController
{
    __weak IBOutlet UILabel *_bigLabel;
    __weak IBOutlet UILabel *_progressLabel;
}
@property (nonatomic, weak, readonly) UILabel* bigLabel;
@property (nonatomic, weak, readonly) UILabel* progressLabel;

- (void) stopAnim;
@end
