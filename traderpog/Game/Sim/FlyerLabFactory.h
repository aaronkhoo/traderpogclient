//
//  FlyerLabFactory.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/6/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FlyerLabFactory : NSObject
{
    NSMutableDictionary* _colorPacks;
    NSMutableDictionary* _upgradePacks;
}
// singleton
+(FlyerLabFactory*) getInstance;
+(void) destroyInstance;

@end
