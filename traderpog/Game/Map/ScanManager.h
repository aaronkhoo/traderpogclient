//
//  ScanManager.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/19/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HiAccuracyLocator;
@interface ScanManager : NSObject
{
    unsigned int _state;
    HiAccuracyLocator* _locator;
}
@property (nonatomic) unsigned int state;
@property (nonatomic,readonly) HiAccuracyLocator* locator;

// singleton
+(ScanManager*) getInstance;
+(void) destroyInstance;

@end
