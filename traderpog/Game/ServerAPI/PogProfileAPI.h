//
//  PogProfileAPI.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 4/15/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PogProfileDelegate.h"

// notifications
extern NSString* const kPogProfileNotificationDidNewUserLogin;

@interface PogProfileAPI : NSObject
{
    NSString* _uuid;
    NSString* _userId;
    NSObject<PogProfileDelegate>* _delegate;
}
@property (nonatomic,readonly) NSString* uuid;
@property (nonatomic,readonly) NSString* userId;
@property (nonatomic) NSObject<PogProfileDelegate>* delegate;

- (void) newUserWithEmail:(NSString*)email;



// singleton
+(PogProfileAPI*) getInstance;
+(void) destroyInstance;


@end
