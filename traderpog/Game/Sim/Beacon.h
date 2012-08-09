//
//  Beacon.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Beacon : NSObject
{
    NSString* _beaconId;
    NSString* _postId;
}
@property (nonatomic,readonly) NSString* beaconId;
@property (nonatomic,readonly) NSString* postId;

- (id) initWithBeaconId:(NSString*)beaconId postId:(NSString *)postId;
@end
