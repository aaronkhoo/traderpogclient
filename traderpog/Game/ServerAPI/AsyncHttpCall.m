//
//  AsynchHttpCall.m
//  traderpog
//
//  Created by Aaron Khoo on 8/28/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "AsyncHttpCall.h"

// encoding keys
static NSString* const kKeyVersion = @"version";
static NSString* const kKeyNumTries = @"numtries";
static NSString* const kKeyType = @"type";
static NSString* const kKeyPath= @"path";
static NSString* const kKeyParams = @"params";
static NSString* const kKeyHeaders = @"headers";
static NSString* const kKeyMsg = @"msg";

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

#pragma mark - NSCoding
- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_createdVersion forKey:kKeyVersion];
    [aCoder encodeInteger:_numTries forKey:kKeyNumTries];
    [aCoder encodeObject:_path forKey:kKeyPath];
    [aCoder encodeObject:_parameters forKey:kKeyParams];
    [aCoder encodeObject:_headers forKey:kKeyHeaders];
    [aCoder encodeObject:_failureMsg forKey:kKeyMsg];
    [aCoder encodeInteger:_type forKey:kKeyType];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    _createdVersion = [aDecoder decodeObjectForKey:kKeyVersion];
    _numTries = [[aDecoder decodeObjectForKey:kKeyNumTries] integerValue];
    _path = [aDecoder decodeObjectForKey:kKeyPath];
    _parameters = [aDecoder decodeObjectForKey:kKeyParams];
    _headers = [aDecoder decodeObjectForKey:kKeyHeaders];
    _failureMsg = [aDecoder decodeObjectForKey:kKeyMsg];
    _type = [aDecoder decodeIntegerForKey:kKeyType];
    return self;
}

@end
