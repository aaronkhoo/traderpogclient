//
//  SoundManager.h
//  CobraPanic
//
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVAudioPlayer.h>

@class SoundClip;
@interface SoundManager : NSObject<AVAudioPlayerDelegate>
{
    NSMutableDictionary*    clipRegistry;
    NSMutableDictionary*    oneShotRegistry;
    NSMutableDictionary*    defaultVolumeDict;

    // one-shot effects
    NSMutableSet*           oneShotEffectsStartSet;
    
    // looping effects controls (multiple looping effects at a time)
    NSMutableSet*           curLoopingEffectsStartSet;
    NSMutableSet*           curLoopingEffectsStopSet;
    NSMutableSet*           curLoopingEffects;
    BOOL                    resumeLoopingEffects;
    
	// music controls (up to two songs at a time)
    float                   musicFadeCur;
    float                   musicFadeTgt;
    float                   musicFadeIncr;
    BOOL                    musicFade;
    BOOL                    musicFadingOut;
    SoundClip*              curBGM1;
    SoundClip*              curBGM2;
    
    // manager controls
    BOOL                    _playClipAllowed;
    BOOL                    enabled;
}
@property (nonatomic,retain) SoundClip* curBGM1;
@property (nonatomic,retain) SoundClip* curBGM2;
@property (nonatomic,retain) NSMutableDictionary* clipRegistry;
@property (nonatomic,retain) NSMutableDictionary* oneShotRegistry;
@property (nonatomic,retain) NSMutableSet* oneShotEffectsStartSet;
@property (nonatomic,retain) NSMutableSet* curLoopingEffectsStartSet;
@property (nonatomic,retain) NSMutableSet* curLoopingEffectsStopSet;
@property (nonatomic,retain) NSMutableSet* curLoopingEffects;
@property (nonatomic,readonly) BOOL enabled;

+ (SoundManager*) getInstance;
+ (void) destroyInstance;

// one-shot effects
- (void) playImmediateClip:(NSString*)name;
- (void) playClip:(NSString*)name;

// looping effects
- (void) startEffectClip:(NSString*)name;
- (void) stopEffectClip:(NSString*)name;
- (void) pauseLoopingEffects;
- (void) resumeLoopingEffects;

// music (one song at a time)
- (void) playMusic:(NSString*)musicName doLoop:(BOOL)loop;
- (void) playMusic:(NSString*)musicName doLoop:(BOOL)loop atVolume:(float)volume;
- (void) pauseMusic;
- (void) resumeMusic;
- (void) stopMusic;

// music2 (one song at a time; can happen on top of music1 above)
- (void) playMusic2:(NSString*)musicName doLoop:(BOOL)loop;
- (void) playMusic2:(NSString*)musicName doLoop:(BOOL)loop atVolume:(float)volume;
- (void) fadeInMusic2:(NSString*)musicName doLoop:(BOOL)loop;
- (void) fadeOutMusic2;
- (void) setVolumeMusic2:(float)newVolume;
- (void) pauseMusic2;
- (void) resumeMusic2;
- (void) stopMusic2;

- (void) disallowPlayClip;
- (void) allowPlayClip;
- (void) enableManager;
- (void) disableManager;
- (void) update;

// AppEvent methods
- (void) resignActive;
- (void) restoreActive;

// Options Menu
- (void) toggleSoundOnOff:(id)sender;
- (void) toggleSound;

@end
