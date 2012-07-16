//
//  GameManager.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ModalNavDelegate.h"
#import "HttpCallbackDelegate.h"

enum kGameStates
{
    kGameStateNew = 0,
    kGameStateGameLoop,
    
    kGameStateNum
};

@class Player;
@class LoadingScreen;
@class CLLocation;
@interface GameManager : NSObject<HttpCallbackDelegate,ModalNavDelegate>
{
    int _gameState;

    __weak LoadingScreen* _loadingScreen;
}
@property (nonatomic,readonly) int gameState;
@property (nonatomic,weak) LoadingScreen* loadingScreen;

// public methods
- (void) loadGame;
- (void) selectNextGameUI;
+ (NSString*) documentsDirectory;

// singleton
+(GameManager*) getInstance;
+(void) destroyInstance;

@end
