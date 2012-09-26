//
//  LoadingScreen.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^LoadingDismissCompletion)(void);

@interface LoadingScreen : UIViewController
{
    __weak IBOutlet UILabel *_bigLabel;
    __weak IBOutlet UILabel *_progressLabel;
}
@property (nonatomic, weak, readonly) UILabel* bigLabel;
@property (nonatomic, weak, readonly) UILabel* progressLabel;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;

- (void) dismissWithCompletion:(LoadingDismissCompletion)completion;
@end
