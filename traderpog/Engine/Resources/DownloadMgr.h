//
//  DownloadMgr.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 9/6/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DownloadMgr : NSObject

// singleton
+(DownloadMgr*) getInstance;
+(void) destroyInstance;

@end
