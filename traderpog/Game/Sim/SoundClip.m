//
//  SoundClip.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/20/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "SoundClip.h"
#import "SoundManager.h"



@implementation SoundClip
@synthesize clipPath;
@synthesize audioPlayer;
@synthesize defaultVolume;
@synthesize playerState;
@synthesize isLooping;

- (id) initWithFilepath:(NSString *)path volume:(float)volume isLooping:(BOOL)loopYesNo
{
    self = [super init];
    if (self) 
    {
        AVAudioPlayer* newPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:NULL];
        newPlayer.delegate = self;
        newPlayer.volume = volume;
        if(loopYesNo)
        {
            newPlayer.numberOfLoops = -1;
        }
        [newPlayer prepareToPlay];
     
        self.clipPath = path;
        self.audioPlayer = newPlayer;
        self.defaultVolume = volume;
        self.playerState = PLAYER_STATE_STOPPED;
        self.isLooping = loopYesNo;
        if(loopYesNo)
        {
            newPlayer.numberOfLoops = -1;
        }
    }
    
    return self;
}

- (void) dealloc
{
    self.clipPath = nil;
    self.audioPlayer = nil;
}

- (void) play
{
    [self playAtVolume:defaultVolume];
}

- (void) playAtVolume:(float)volume
{
//    if(self.playerState != PLAYER_STATE_PLAYING)
    {
        if(isLooping)
        {
            // play indefinitely
            audioPlayer.numberOfLoops = -1;
        }
        else
        {
            // play once
            audioPlayer.numberOfLoops = 0;
        }
        audioPlayer.volume = volume;
        if([[SoundManager getInstance] enabled])
        {
            [audioPlayer play];
        }
        self.playerState = PLAYER_STATE_PLAYING;
    }
}

- (void) stop
{
//    if((self.playerState == PLAYER_STATE_PLAYING) ||
//       (self.playerState == PLAYER_STATE_PAUSED))
    {
        [audioPlayer stop];
        audioPlayer.currentTime = [audioPlayer duration];
        self.playerState = PLAYER_STATE_STOPPED;
        
        // after stop, re-create the audioPlayer
        // otherwise, subsequent plays may fail to start for some reason
        AVAudioPlayer* newPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:clipPath] error:NULL];
        newPlayer.delegate = self;
        newPlayer.volume = defaultVolume;
        if(isLooping)
        {
            newPlayer.numberOfLoops = -1;
        }
        [newPlayer prepareToPlay];

        self.audioPlayer = newPlayer;
    }
}

- (void) pause
{
    [audioPlayer pause];
    self.playerState = PLAYER_STATE_PAUSED;
}

- (void) resume
{
    if([[SoundManager getInstance] enabled])
    {
        [audioPlayer play];
    }
    self.playerState = PLAYER_STATE_PLAYING;
}

- (void) setVolume:(float)volume
{
    audioPlayer.volume = volume;
}

#pragma mark -
#pragma mark AVAudioPlayerDelegate methods

- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
/*
    if([clipPath rangeOfString:@"BlimpLargeLoop"].location != NSNotFound)
    {
        NSLog(@"large blimp sound stopped");
        if(isLooping)
        {
            player.numberOfLoops = -1;
            [player play];
        }
    }
 */
    self.playerState = PLAYER_STATE_STOPPED;
}
 

@end
