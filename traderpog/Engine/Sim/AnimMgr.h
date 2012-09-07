//
//  AnimMgr.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 9/6/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AnimDelegate.h"

@interface AnimMgr : NSObject
{
    NSMutableArray* _animObjects;
}

- (void) addAnimObject:(NSObject<AnimDelegate>*)animObject;
- (void) removeAnimObject:(NSObject<AnimDelegate>*)animObject;
- (void) update:(NSTimeInterval)elapsed;

// singleton
+(AnimMgr*) getInstance;
+(void) destroyInstance;

@end
