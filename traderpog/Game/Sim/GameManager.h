//
//  GameManager.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PogProfileDelegate.h"

enum kGameStates
{
    kGameStateFrontUI = 0,
    kGameStateSetupNewPlayer,
    kGameStateGameView,
    
    kGameStateNum
};

@class Player;
@class LoadingScreen;
@class CLLocation;
@interface GameManager : NSObject<PogProfileDelegate>
{
    int _gameState;
    Player* _player;

    __weak LoadingScreen* _loadingScreen;
    
}
@property (nonatomic,readonly) int gameState;
@property (nonatomic,strong) Player* player;
@property (nonatomic,weak) LoadingScreen* loadingScreen;

// public methods
- (void) setupNewPlayerWithEmail:(NSString*)email loadingScreen:(LoadingScreen*)loadingScreen;
- (void) completeSetupNewPlayer;
- (void) abortSetupNewPlayer;
- (void) setupHomebaseAtLocation:(CLLocation*)location;

- (void) loadGame;

// singleton
+(GameManager*) getInstance;
+(void) destroyInstance;

@end
