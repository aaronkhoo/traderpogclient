//
//  GameAnim.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 9/22/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GameAnim : NSObject

// returns true if imageview successfully refreshed; otherwise, false
- (BOOL) refreshImageView:(UIImageView*)imageView withClipNamed:(NSString*)clipName;

// singleton
+(GameAnim*) getInstance;
+(void) destroyInstance;

@end
