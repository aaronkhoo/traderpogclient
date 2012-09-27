//
//  AnimMgr.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 9/6/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "AnimMgr.h"
#import "AnimClip.h"

@implementation AnimMgr

- (id) init
{
    self = [super init];
    if(self)
    {
        _animObjects = [NSMutableArray arrayWithCapacity:10];
        _clipReg = [NSMutableDictionary dictionaryWithCapacity:10];
    }
    return self;
}

- (void) addAnimObject:(NSObject<AnimDelegate>*)animObject
{
    [_animObjects addObject:animObject];
}

- (void) removeAnimObject:(NSObject<AnimDelegate>*)animObject
{
    [_animObjects removeObject:animObject];
}

- (void) update:(NSTimeInterval)elapsed
{
    for(NSObject<AnimDelegate>* cur in _animObjects)
    {
        [cur animUpdate:elapsed];
    }
}

#pragma mark - clips anim

// returns an array with names of loaded clips
- (NSArray*) addClipsFromPlistFile:(NSString *)filename
{
    NSMutableArray* loadedNames = [NSMutableArray arrayWithCapacity:10];
    NSString* filepath = [[NSBundle mainBundle] pathForResource:filename ofType:@"plist"];
    NSDictionary* newClips = [NSDictionary dictionaryWithContentsOfFile:filepath];
    for(NSString* key in newClips)
    {
        if(![_clipReg objectForKey:key])
        {
            NSDictionary* clipDict = [newClips objectForKey:key];
            AnimClip* clip = [[AnimClip alloc] initWithDictionary:clipDict];
            [_clipReg setObject:clip forKey:key];
            [loadedNames addObject:key];
        }
        else
        {
            NSLog(@"Warning: clip %@ from file %@ not added; same name already exists", key, filename);
        }
    }
    return loadedNames;
}

- (void) removeClipsInNameArray:(NSArray *)nameArray
{
    for(NSString* name in nameArray)
    {
        [_clipReg removeObjectForKey:name];
    }
}

- (AnimClip*) getClipWithName:(NSString *)clipname
{
    return [_clipReg objectForKey:clipname];
}

#pragma mark - Singleton
static AnimMgr* singleton = nil;
+ (AnimMgr*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
			singleton = [[AnimMgr alloc] init];
		}
	}
	return singleton;
}

+ (void) destroyInstance
{
	@synchronized(self)
	{
		singleton = nil;
	}
}

@end
