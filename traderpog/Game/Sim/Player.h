//
//  Player.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Player : NSObject<NSCoding>
{
    // internal
    NSString* _createdVersion;
    
    // id
    NSString* _userId;
}
- (id) initWithUserId:(NSString*)userId;

// system
- (void) appDidEnterBackground;

// singleton
+(Player*) getInstance;
+(void) destroyInstance;

@end
