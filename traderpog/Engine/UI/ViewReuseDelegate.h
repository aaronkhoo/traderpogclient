//
//  ViewReuseDelegate.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/4/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ViewReuseDelegate <NSObject>
- (NSString*) reuseIdentifier;
- (void) prepareForQueue;
@end
