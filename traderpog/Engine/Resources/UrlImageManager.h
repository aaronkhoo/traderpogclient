//
//  UrlImageManager.h
//  traderpog
//
//  Created by Aaron Khoo on 10/5/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UrlImage.h"

@interface UrlImageManager : NSObject
{
    NSMutableDictionary* _urlImages;
}

- (UrlImage*) getCachedImage:(NSString*)fbid;
- (void) insertImageToCache:(NSString*)fbid image:(UrlImage*)image;

// singleton
+(UrlImageManager*) getInstance;
+(void) destroyInstance;

@end
