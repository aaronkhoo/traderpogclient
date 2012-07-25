//
//  GameManager.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GameViewController.h"
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
@class Flyer;
@class TradePost;
@interface GameManager : NSObject<HttpCallbackDelegate,ModalNavDelegate>
{
    int _gameState;

    __weak LoadingScreen* _loadingScreen;
}
@property (nonatomic,readonly) int gameState;
@property (nonatomic,weak) LoadingScreen* loadingScreen;
@property (nonatomic,strong) GameViewController* gameViewController;

// public methods
- (void) loadGameInfo;
- (void) selectNextGameUI;
- (void) flyer:(Flyer*)flyer departForTradePost:(TradePost*)tradePost;

+ (NSString*) documentsDirectory;

// system
- (void) applicationWillEnterForeground;

// singleton
+(GameManager*) getInstance;
+(void) destroyInstance;

@end
