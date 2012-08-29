//
//  AsyncHttpCallMgr.h
//  traderpog
//
//  Created by Aaron Khoo on 8/28/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AsyncHttpCall.h"
#import "AsyncHttpDelegate.h"

@interface AsyncHttpCallMgr : NSObject<AsyncHttpDelegate>
{
    // Delegate for callbacks to inform interested parties of completion
    __weak NSObject<AsyncHttpDelegate>* _delegate;
}
@property (nonatomic,weak) NSObject<AsyncHttpDelegate>* delegate;

- (void) push:(AsyncHttpCall*) newCall;

// singleton
+(AsyncHttpCallMgr*) getInstance;
+(void) destroyInstance;

@end
