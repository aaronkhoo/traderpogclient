//
//  GameAnim.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 9/22/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GameAnim : NSObject

// singleton
+(GameAnim*) getInstance;
+(void) destroyInstance;

@end
