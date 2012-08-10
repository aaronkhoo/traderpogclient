//
//  ResourceManager.h
//  traderpog
//
//  Created by Aaron Khoo on 8/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HttpCallbackDelegate.h"

static NSString* const kResourceManager_PackageReady = @"ResourceManager_PackageReady";

@interface ResourceManager : NSObject
{
    // Delegate for callbacks to inform interested parties of completion
    __weak NSObject<HttpCallbackDelegate>* _delegate;
}
@property (nonatomic,weak) NSObject<HttpCallbackDelegate>* delegate;

- (void)downloadResourceFileIfNecessary;

// singleton
+(ResourceManager*) getInstance;
+(void) destroyInstance;

@end
