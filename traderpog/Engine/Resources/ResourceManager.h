//
//  ResourceManager.h
//  traderpog
//
//  Created by Aaron Khoo on 8/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ResourceManager : NSObject

- (void)downloadResourceFileIfNecessary;

// singleton
+(ResourceManager*) getInstance;
+(void) destroyInstance;

@end
