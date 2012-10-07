//
//  FlyerColorPack.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/6/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "FlyerColorPack.h"
#import "NSDictionary+Pog.h"

NSString* const kKeyColorRed = @"colorR";
NSString* const kKeyColorGreen = @"colorG";
NSString* const kKeyColorBlue = @"colorB";
NSString* const kKeyColorAlpha = @"alpha";

@implementation FlyerColorPack
@synthesize color = _color;

- (id) init
{
    NSAssert(false, @"must use initDictionary to create FlyerColorPack");
    return nil;
}

- (id) initWithDictionary:(NSDictionary*)dict
{
    self = [super init];
    if(self)
    {
        float colorR = [dict getFloatForKey:kKeyColorRed withDefault:255.0f];
        float colorG = [dict getFloatForKey:kKeyColorGreen withDefault:255.0f];
        float colorB = [dict getFloatForKey:kKeyColorBlue withDefault:255.0f];
        float alpha = [dict getFloatForKey:kKeyColorAlpha withDefault:1.0f];
        
        _color = [UIColor colorWithRed:colorR/255.0f
                                 green:colorG/255.0f
                                  blue:colorB/255.0f
                                 alpha:alpha];
    }
    return self;
}
@end
