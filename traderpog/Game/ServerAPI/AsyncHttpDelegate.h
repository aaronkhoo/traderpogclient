//
//  AsyncHttpDelegate.h
//  traderpog
//
//  Created by Aaron Khoo on 8/28/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AsyncHttpDelegate <NSObject>
- (void) didCompleteAsyncHttpCallback:(BOOL)success;
@end
