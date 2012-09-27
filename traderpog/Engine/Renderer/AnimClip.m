//
//  AnimClip.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 9/26/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "AnimClip.h"
#import "ImageManager.h"

static NSString* const kKeyIsLoop = @"loop";
static NSString* const kKeyFps = @"fps";
static NSString* const kKeyFrames = @"frames";

@implementation AnimClip
@synthesize framesPerSec = _framesPerSec;
@synthesize isLoop = _isLoop;

- (id) init
{
    NSAssert(false, @"must use initDictionary to create AnimClip");
    return nil;
}

- (id) initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if(self)
    {
        NSNumber* loopNum = [dict objectForKey:kKeyIsLoop];
        if(loopNum)
        {
            _isLoop = [loopNum boolValue];
        }
        else
        {
            _isLoop = NO;
        }
        NSNumber* fpsNum = [dict objectForKey:kKeyFps];
        if(fpsNum)
        {
            _framesPerSec = [fpsNum floatValue];
        }
        else
        {
            _framesPerSec = 6.0f;
        }
        NSArray* frameNames = [dict objectForKey:kKeyFrames];
        if(frameNames && [frameNames count])
        {
            _frames = [NSMutableArray arrayWithCapacity:[frameNames count]];
            for(NSString* name in frameNames)
            {
                UIImage* image = [[ImageManager getInstance] getImage:name];
                if(!image)
                {
                    image = [[ImageManager getInstance] getImage:@"checkboard.png"];
                }
                [_frames addObject:image];
            }
        }
    }
    return self;
}

- (float) secondsPerLoop
{
    float result = 1.0f;
 
    if(_frames && [_frames count])
    {
        result = (1.0f / _framesPerSec) * [_frames count];
    }
    
    return result;
}

- (NSArray*) imagesArray
{
    return _frames;
}

@end
