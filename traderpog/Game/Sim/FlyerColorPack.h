//
//  FlyerColorPack.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/6/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const kKeyColorRed;
extern NSString* const kKeyColorGreen;
extern NSString* const kKeyColorBlue;
extern NSString* const kKeyColorAlpha;

@interface FlyerColorPack : NSObject
{
    UIColor* _color;
    NSString* _name;
}
@property (nonatomic,readonly) UIColor* color;
@property (nonatomic,readonly) NSString* name;

- (id) initWithDictionary:(NSDictionary*)dict;
@end
