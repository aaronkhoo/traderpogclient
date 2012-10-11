//
//  SoundClip.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/20/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVAudioPlayer.h>

enum PLAYERSTATES
{
    PLAYER_STATE_INVALID = 0,
    PLAYER_STATE_STOPPED,
    PLAYER_STATE_PLAYING,
    PLAYER_STATE_PAUSED,
    
    PLAYER_STATE_NUM
};
@class AVAudioPlayer;
@interface SoundClip : NSObject<AVAudioPlayerDelegate>
{
    NSString* clipPath;
    AVAudioPlayer* audioPlayer;
    float defaultVolume;
    unsigned int playerState;
    BOOL isLooping;
}
@property (nonatomic,retain) NSString* clipPath;
@property (nonatomic,retain) AVAudioPlayer* audioPlayer;
@property (nonatomic,assign) float defaultVolume;
@property (nonatomic,assign) unsigned int playerState;
@property (nonatomic,assign) BOOL isLooping;
- (id) initWithFilepath:(NSString*)path volume:(float)volume isLooping:(BOOL)loopYesNo;
- (void) play;
- (void) playAtVolume:(float)volume;
- (void) stop;
- (void) pause;
- (void) resume;
- (void) setVolume:(float)volume;
@end
