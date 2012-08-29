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

@interface AsyncHttpCallMgr : NSObject<AsyncHttpDelegate, NSCoding>
{
    // Delegate for callbacks to inform interested parties of completion
    __weak NSObject<AsyncHttpDelegate>* _delegate;
}
@property (nonatomic,weak) NSObject<AsyncHttpDelegate>* delegate;

- (void) newAsyncHttpCall:(NSString*)path
           current_params:(NSDictionary*)params
          current_headers:(NSDictionary*)headers
              current_msg:(NSString*)msg
             current_type:(httpCallType)type;
- (void) startCalls;
- (void) applicationWillTerminate;

// singleton
+(AsyncHttpCallMgr*) getInstance;
+(void) destroyInstance;

@end
