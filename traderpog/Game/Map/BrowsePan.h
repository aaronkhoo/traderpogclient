//
//  BrowsePan.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/29/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MapControl;
@class BrowseArea;
@interface BrowsePan : NSObject<UIGestureRecognizerDelegate>
{
    __weak MapControl* _map;
    __weak BrowseArea* _browseArea;
}
@property (nonatomic,weak) MapControl* map;
@property (nonatomic,weak) BrowseArea* browseArea;

- (id) initWithMap:(MapControl*)map browseArea:(BrowseArea*)browseArea;
- (void) handleGesture:(UIGestureRecognizer*)gestureRecognizer;
- (BOOL) isPanEnding;
- (BOOL) enforceBrowseArea;
@end
