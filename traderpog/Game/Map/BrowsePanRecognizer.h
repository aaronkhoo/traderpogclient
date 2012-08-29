//
//  BrowsePanRecognizer.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/29/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UIKit/UIGestureRecognizerSubclass.h>

@class MapControl;
@class BrowseArea;

@interface BrowsePanRecognizer : UIGestureRecognizer<UIGestureRecognizerDelegate>
{
    __weak MapControl* _map;
    __weak BrowseArea* _browseArea;
}
@property (nonatomic,weak) MapControl* map;
@property (nonatomic,weak) BrowseArea* browseArea;

- (id) initWithMap:(MapControl*)map browseArea:(BrowseArea*)browseArea;

@end
