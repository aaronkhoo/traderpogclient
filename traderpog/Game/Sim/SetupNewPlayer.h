//
//  SetupNewPlayer.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PogProfileDelegate.h"

@class LoadingScreen;
@interface SetupNewPlayer : NSObject<PogProfileDelegate>

- (id) initWithEmail:(NSString*)email loadingScreen:(LoadingScreen*)loadingScreen;
@end
