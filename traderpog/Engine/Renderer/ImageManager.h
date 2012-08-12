//
//  ImageManager.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/8/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageManager : NSObject

// frontend menu
- (void) loadFrontMenuBackgroundNamed:(NSString*)imageName;       // ok to call this repeatedly
- (void) unloadFrontMenuBackground;

- (UIImage*) getImage:(NSString*)name fallbackNamed:(NSString*)fallback;

// singleton
+(ImageManager*) getInstance;
+(void) destroyInstance;


@end
