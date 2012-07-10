//
//  DebugOptions.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 5/3/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface DebugOptions : NSObject
{
    NSString* _serverIp;
    BOOL _useServer;
}
@property (nonatomic) NSString* serverIp;
@property (nonatomic) BOOL useServer;

- (void) setOnOffUseServer:(id)sender;

// singleton
+(DebugOptions*) getInstance;
+(void) destroyInstance;


@end
