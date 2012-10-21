//
//  ObjectivesMgr.h
//  traderpog
//
//  player objectives manager
//  this is primarily used to guide new players through the experience
//
//  Created by Shu Chiun Cheah on 10/21/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ObjectivesMgr : NSObject

// singleton
+(ObjectivesMgr*) getInstance;
+(void) destroyInstance;

@end
