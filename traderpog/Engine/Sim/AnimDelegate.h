//
//  AnimDelegate.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 9/6/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AnimDelegate <NSObject>
- (void) animUpdate:(NSTimeInterval)elapsed;
@end
