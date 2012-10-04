//
//  ViewReuseQueue.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/4/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ViewReuseDelegate.h"

@interface ViewReuseQueue : NSObject
{
    NSMutableDictionary* _registry;
}

- (void) clearQueue;
- (void) queueView:(UIView<ViewReuseDelegate>*)view;
- (UIView*) dequeueReusableViewWithIdentifier:(NSString*)identifier;

@end
