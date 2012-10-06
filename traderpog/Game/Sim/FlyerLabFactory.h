//
//  FlyerLabFactory.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/6/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FlyerLabFactory : NSObject

// singleton
+(FlyerLabFactory*) getInstance;
+(void) destroyInstance;

@end
