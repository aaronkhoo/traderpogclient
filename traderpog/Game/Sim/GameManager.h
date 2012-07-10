//
//  GameManager.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PogProfileDelegate.h"

@class Player;
@class LoadingScreen;
@interface GameManager : NSObject<PogProfileDelegate>
{
    Player* _player;

    __weak LoadingScreen* _loadingScreen;
}
@property (nonatomic,strong) Player* player;
@property (nonatomic,weak) LoadingScreen* loadingScreen;

// public methods
- (void) newGameWithEmail:(NSString*)email;
- (void) loadGame;

// singleton
+(GameManager*) getInstance;
+(void) destroyInstance;

@end
