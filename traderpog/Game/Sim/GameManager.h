//
//  GameManager.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GameManager : NSObject
{
    BOOL _isUserRegistered;
}
@property (nonatomic) BOOL isUserRegistered;

// singleton
+(GameManager*) getInstance;
+(void) destroyInstance;

@end
