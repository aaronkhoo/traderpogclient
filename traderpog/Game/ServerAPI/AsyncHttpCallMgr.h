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

- (void) newAsyncHttpCall:(NSString*)path
           current_params:(NSDictionary*)params
          current_headers:(NSDictionary*)headers
              current_msg:(NSString*)msg
             current_type:(httpCallType)type;
- (BOOL) startCalls;
- (BOOL) callsRemain;
- (void) applicationDidEnterBackground;
- (void) applicationWillTerminate;
- (void) removeAsyncHttpCallMgrData;
- (void) addDelegateInstance:(__weak NSObject<AsyncHttpDelegate>*) delegate;

// singleton
+(AsyncHttpCallMgr*) getInstance;
+(void) destroyInstance;

@end
