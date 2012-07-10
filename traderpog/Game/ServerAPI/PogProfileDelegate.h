//
//  PogProfileDelegate.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PogProfileDelegate <NSObject>
- (void) didCompleteAccountRegistrationForUserId:(NSString*)userId;
@end
