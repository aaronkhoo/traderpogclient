//
//  HttpCallbackDelegate.h
//  traderpog
//
//  Created by Aaron Khoo on 7/13/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HttpCallbackDelegate <NSObject>
- (void) didCompleteHttpCallback:(NSString*)callName, BOOL success;
@end
