//
//  AnimMgr.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 9/6/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AnimDelegate.h"

@class AnimClip;
@interface AnimMgr : NSObject
{
    NSMutableArray* _animObjects;
    NSMutableDictionary* _clipReg;
}

// procedural anims
- (void) addAnimObject:(NSObject<AnimDelegate>*)animObject;
- (void) removeAnimObject:(NSObject<AnimDelegate>*)animObject;
- (void) update:(NSTimeInterval)elapsed;

// clip anims
- (NSArray*) addClipsFromPlistFile:(NSString*)filename;
- (void) removeClipsInNameArray:(NSArray*)nameArray;
- (AnimClip*) getClipWithName:(NSString*)clipname;

// singleton
+(AnimMgr*) getInstance;
+(void) destroyInstance;

@end
