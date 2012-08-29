//
//  AsynchHttpCall.m
//  traderpog
//
//  Created by Aaron Khoo on 8/28/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "AsyncHttpCall.h"

@implementation AsyncHttpCall
@synthesize path = _path;
@synthesize parameters = _parameters;
@synthesize headers = _headers;
@synthesize failureMsg = _failureMsg;
@synthesize type = _type;
@synthesize numTries = _numTries;

- (id) initWithValues:(NSString*)current_path
       current_params:(NSDictionary*)current_params
      current_headers:(NSDictionary*)current_headers
          current_msg:(NSString*)current_msg
         current_type:(httpCallType)current_type
{
    self = [super init];
    if (self)
    {
        _numTries = 0;
        _path = current_path;
        _parameters = current_params;
        _headers = current_headers;
        _failureMsg = current_msg;
        _type = current_type;
    }
    return self;
}

@end
