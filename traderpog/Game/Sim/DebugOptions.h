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
    BOOL _localDev;
    BOOL _speed100x;
}
@property (nonatomic) NSString* serverIp;
@property (nonatomic) BOOL useServer;
@property (nonatomic) BOOL localDev;
@property (nonatomic) BOOL speed100x;

- (void) setOnOffUseServer:(id)sender;
- (void) setOnOffLocalDev:(id)sender;
- (void) setOnOffSpeed100x:(id)sender;

// singleton
+(DebugOptions*) getInstance;
+(void) destroyInstance;


@end
