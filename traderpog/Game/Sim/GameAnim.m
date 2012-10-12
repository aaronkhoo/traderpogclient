//
//  GameAnim.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 9/22/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "GameAnim.h"
#import "AnimMgr.h"
#import "AnimClip.h"

@interface GameAnim ()
{
    // names of clips loaded by this class
    NSArray* _clipnames;
}
@end

@implementation GameAnim
- (id) init
{
    self = [super init];
    if(self)
    {
        _clipnames = [[AnimMgr getInstance] addClipsFromPlistFile:@"gameanim"];
    }
    return self;
}

- (void) dealloc
{
    [[AnimMgr getInstance] removeClipsInNameArray:_clipnames];
    _clipnames = nil;
}

- (BOOL) refreshImageView:(UIImageView*)imageView withClipNamed:(NSString*)clipName
{
    BOOL refreshed = NO;
    AnimClip* clip = [[AnimMgr getInstance] getClipWithName:clipName];
    if(clip)
    {
        [imageView setAnimationImages:[clip imagesArray]];
        [imageView setAnimationDuration:[clip secondsPerLoop]];
        refreshed = YES;
    }
    return refreshed;
}

#pragma mark - Singleton
static GameAnim* singleton = nil;
+ (GameAnim*) getInstance
{
	@synchronized(self)
	{
        if (!singleton)
        {
            singleton = [[GameAnim alloc] init];
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
