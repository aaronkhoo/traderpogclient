//
//  AsynchHttpCall.h
//  traderpog
//
//  Created by Aaron Khoo on 8/28/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    putType = 1,
    postType = 2
} httpCallType;

@interface AsyncHttpCall : NSObject<NSCoding>
{
    // internal
    NSString* _createdVersion;
    
    NSInteger _numTries;
    httpCallType _type;
    NSString* _path;
    NSDictionary* _parameters;
    NSDictionary* _headers;
    NSString* _failureMsg;
}
@property (nonatomic) NSInteger numTries;
@property (nonatomic) httpCallType type;
@property (nonatomic,readonly) NSString* path;
@property (nonatomic,readonly) NSDictionary* parameters;
@property (nonatomic,readonly) NSDictionary* headers;
@property (nonatomic,readonly) NSString* failureMsg;

- (id) initWithValues:(NSString*)current_path
       current_params:(NSDictionary*)current_params
      current_headers:(NSDictionary*)current_headers
          current_msg:(NSString*)current_msg
         current_type:(httpCallType)current_type;
@end
