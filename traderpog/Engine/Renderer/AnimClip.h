//
//  AnimClip.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 9/26/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AnimClip : NSObject
{
    NSMutableArray* _frames;
    float _framesPerSec;
    BOOL _isLoop;
}
@property (nonatomic,readonly) float framesPerSec;
@property (nonatomic,readonly) BOOL isLoop;

- (id) initWithDictionary:(NSDictionary*)dict;
- (float) secondsPerLoop;
- (NSArray*) imagesArray;

@end
