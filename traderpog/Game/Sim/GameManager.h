//
//  GameManager.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AsyncHttpDelegate.h"
#import "GameViewController.h"
#import "ModalNavDelegate.h"
#import "HttpCallbackDelegate.h"

enum kGameStates
{
    kGameStateNew = 0,
    
    kGameStateInGameFirst,
    kGameStateGameLoop = kGameStateInGameFirst,
    kGameStateHomeSelect,
    kGameStateFlyerSelect,
    kGameStateInGameLast,
    
    kGameStateNum = kGameStateInGameLast
};

@class Player;
@class LoadingScreen;
@class CLLocation;
@class Flyer;
@class TradePost;
@class WheelControl;
@interface GameManager : NSObject<AsyncHttpDelegate,HttpCallbackDelegate,ModalNavDelegate>
{
    int _gameState;

    __weak LoadingScreen* _loadingScreen;
}
@property (nonatomic,readonly) int gameState;
@property (nonatomic,weak) LoadingScreen* loadingScreen;
@property (nonatomic,strong) GameViewController* gameViewController;

// public methods
- (void) selectNextGameUI;
- (void) flyer:(Flyer*)flyer departForTradePost:(TradePost*)tradePost;

// in-game UI flows
- (void) showHomeSelectForFlyer:(Flyer*)flyer;
- (void) showFlyerSelectForBuyAtPost:(TradePost*)post;
- (void) wheel:(WheelControl*)wheel commitOnTradePost:(TradePost*)tradePost;
- (void) wheel:(WheelControl *)wheel commitOnFlyer:(Flyer *)flyer;
- (void) popGameStateToLoop;

// global UI controls
- (void) haltMapAnnotationCalloutsForDuration:(NSTimeInterval)seconds;
- (BOOL) canShowMapAnnotationCallout;

+ (NSString*) documentsDirectory;

// system
- (void) applicationWillEnterForeground;
- (void) applicationDidEnterBackground;
- (void) clearCache;

// singleton
+(GameManager*) getInstance;
+(void) destroyInstance;

@end
