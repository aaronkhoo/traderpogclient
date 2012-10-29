//
//  SoundManager.mm
//  CobraPanic
//
//

#import "SoundManager.h"
#import "SoundClip.h"
#import "AVFoundation/AVAudioSession.h"

enum SOUNDENABLED_ENUMS
{
    SOUNDENABLED_INVALID = 0,
    SOUNDENABLED_YES,
    SOUNDENABLED_NO
};

static const float MUSICFADE_INCR = 0.005f;
static NSString* const SOUNDMANAGER_ENABLED_KEY = @"SoundManagerEnabled";

@interface SoundManager (SoundManagerPrivate)
- (void) initGlobalClips;
+ (BOOL) boolFromEnabledDefault:(NSInteger)soundEnabled;
+ (NSInteger) enabledDefaultFromBool:(BOOL)soundEnabled;
- (void) addClip:(NSString*)name  fromFile:(NSString*)path defaultVolume:(float)level isLooping:(BOOL)loopYesNo;
- (void) addOneShotClip:(NSString*)name  fromFile:(NSString*)path defaultVolume:(float)level numAVPlayers:(unsigned int)numAVPlayers;
- (void) playOneShot:(NSString*)name;
@end

@implementation SoundManager
@synthesize curBGM1;
@synthesize curBGM2;
@synthesize clipRegistry;
@synthesize oneShotRegistry;
@synthesize oneShotEffectsStartSet;
@synthesize curLoopingEffectsStartSet;
@synthesize curLoopingEffectsStopSet;
@synthesize curLoopingEffects;
@synthesize enabled;


#pragma mark -
#pragma mark Instance methods
- (id) init
{
	if((self = [super init]))
	{
        // init AudioSession
		[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:NULL];
		[[AVAudioSession sharedInstance] setActive:YES error:NULL];
        
        self.clipRegistry = [NSMutableDictionary dictionary];
        self.oneShotRegistry = [NSMutableDictionary dictionary];
		[self initGlobalClips];
        
        // one-shot effects
        self.oneShotEffectsStartSet = [NSMutableSet set];
        
        // looping effects
        self.curLoopingEffectsStartSet = [NSMutableSet set];
        self.curLoopingEffectsStopSet = [NSMutableSet set];
        self.curLoopingEffects = [NSMutableSet set];
        resumeLoopingEffects = NO;
        
        // music
        self.curBGM1 = nil;
        self.curBGM2 = nil;
        musicFade = NO;
        musicFadingOut = NO;
        musicFadeCur = 1.0f;
        musicFadeTgt = 1.0f;
        musicFadeIncr = 0.05f;
        
        // manager controls
        NSInteger soundEnabledDefault = [[NSUserDefaults standardUserDefaults] integerForKey:SOUNDMANAGER_ENABLED_KEY];
        if(SOUNDENABLED_INVALID == soundEnabledDefault)
        {
            enabled = YES;
            [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:SOUNDMANAGER_ENABLED_KEY];
        }
        else
        {
            enabled = [SoundManager boolFromEnabledDefault:soundEnabledDefault];
        }
        
        // limited scope controls (this controls at a higher level)
        _playClipAllowed = YES;
	}
	return self;
}

- (void) dealloc
{
	[self stopMusic];
    [self stopMusic2];
    enabled = NO;
    
    self.curLoopingEffects = nil;
    self.curLoopingEffectsStopSet = nil;
    self.curLoopingEffectsStartSet = nil;
    self.oneShotEffectsStartSet = nil;
    self.curBGM1 = nil;
    self.curBGM2 = nil;
    self.oneShotRegistry = nil;
    self.clipRegistry = nil;
    
    [[AVAudioSession sharedInstance] setActive:NO error:NULL];
}

- (void) addOneShotClip:(NSString *)name fromFile:(NSString *)path defaultVolume:(float)level numAVPlayers:(unsigned int)numAVPlayers
{
    assert(0 < numAVPlayers);
    NSMutableArray* entry = [NSMutableArray arrayWithCapacity:numAVPlayers];
    unsigned int index = 0;
    while(index < numAVPlayers)
    {
        SoundClip* newClip = [[SoundClip alloc] initWithFilepath:path volume:level isLooping:NO];
        [entry addObject:newClip];
        ++index;
    }
    [oneShotRegistry setObject:entry forKey:name];
}

- (void) playOneShot:(NSString *)name
{
    NSMutableArray* cur = [oneShotRegistry objectForKey:name];
    if(cur)
    {
        // play the first idle clip
        for(SoundClip* curClip in cur)
        {
            if([curClip playerState] == PLAYER_STATE_STOPPED)
            {
                [curClip play];
                break;
            }
        }
    }
}

- (void) addClip:(NSString*)name fromFile:(NSString*)path defaultVolume:(float)level isLooping:(BOOL)loopYesNo
{
    SoundClip* newClip = [[SoundClip alloc] initWithFilepath:path volume:level isLooping:loopYesNo];
    [clipRegistry setObject:newClip forKey:name];
}

- (void) playImmediateClip:(NSString *)name
{
    if(enabled)
    {
        if(_playClipAllowed)
        {
            [self playOneShot:name];
        }
    }
}

- (void) playClip:(NSString *)name
{
    if(_playClipAllowed)
    {
        [oneShotEffectsStartSet addObject:name];
    }
}


#pragma mark - Looping Effects

- (void) startEffectClip:(NSString *)name
{
    if(_playClipAllowed)
    {
        SoundClip* clip = [clipRegistry objectForKey:name];
        [curLoopingEffectsStartSet addObject:clip];
    }
}

- (void) stopEffectClip:(NSString *)name
{
    SoundClip* clip = [clipRegistry objectForKey:name];
    [curLoopingEffectsStopSet addObject:clip];
}

- (void) pauseLoopingEffects
{
    for(SoundClip* cur in curLoopingEffects)
    {
        [cur pause];
    }
}

- (void) resumeLoopingEffects
{
    resumeLoopingEffects = YES;
}

#pragma mark - music

- (void) playMusic:(NSString *)musicName doLoop:(BOOL)loop
{
    [self playMusic:musicName doLoop:loop atVolume:-1.0f];
}


- (void) playMusic:(NSString *)musicName doLoop:(BOOL)loop atVolume:(float)volume
{
    SoundClip* clip = [clipRegistry objectForKey:musicName];
    assert(clip);
    if(self.curBGM1 != clip)
    {
        if(self.curBGM1)
        {
            [self.curBGM1 stop];
        }
        clip.isLooping = loop;
        self.curBGM1 = clip;
    }
    
    // play it, either new or resume
    if(0.0f > volume)
    {
        [self.curBGM1 play];
    }
    else
    {
        [self.curBGM1 playAtVolume:volume];
    }
}

- (void) stopMusic
{
    if(self.curBGM1)
    {
        [curBGM1 stop];
        self.curBGM1 = nil;
    }
}

- (void) pauseMusic
{
    if(self.curBGM1)
    {
        [self.curBGM1 pause];
    }
}

- (void) resumeMusic
{
    if(self.curBGM1)
    {
        [self.curBGM1 resume];
    }
}

#pragma mark - music2
- (void) playMusic2:(NSString *)musicName doLoop:(BOOL)loop
{
    [self playMusic2:musicName doLoop:loop atVolume:-1.0f];
}


- (void) playMusic2:(NSString *)musicName doLoop:(BOOL)loop atVolume:(float)volume
{
    SoundClip* clip = [clipRegistry objectForKey:musicName];
    assert(clip);
    if(self.curBGM2 != clip)
    {
        if(self.curBGM2)
        {
            [self.curBGM2 stop];
        }
        clip.isLooping = loop;
        self.curBGM2 = clip;
    }
    
    // play it, either new or resume
    if(0.0f > volume)
    {
        [self.curBGM2 play];
    }
    else
    {
        [self.curBGM2 playAtVolume:volume];
    }
}

- (void) fadeInMusic2:(NSString *)musicName doLoop:(BOOL)loop
{
    SoundClip* clip = [clipRegistry objectForKey:musicName];
    if(clip)
    {
        musicFadeCur = 0.005f;
        [self playMusic2:musicName doLoop:loop atVolume:musicFadeCur];
        [self setVolumeMusic2:[clip defaultVolume]];
    }
}

- (void) fadeOutMusic2
{
    [self setVolumeMusic2:0.005f];
    musicFadingOut = YES;
}

- (void) stopMusic2
{
    if(self.curBGM2)
    {
        [curBGM2 stop];
        musicFade = NO;
        musicFadingOut = NO;
        self.curBGM2 = nil;
    }
}

- (void) pauseMusic2
{
    if(self.curBGM2)
    {
        [self.curBGM2 pause];
    }
}

- (void) resumeMusic2
{
    if(self.curBGM2)
    {
        [self.curBGM2 resume];
    }
}

- (void) setVolumeMusic2:(float)newVolume
{
    if([self curBGM2])
    {
        musicFade = YES;
        musicFadeTgt = newVolume;
        if(musicFadeCur < musicFadeTgt)
        {
            musicFadeIncr = MUSICFADE_INCR;
        }
        else
        {
            musicFadeIncr = -MUSICFADE_INCR;
        }
    }
}
#pragma mark - Manager Controls

- (void) allowPlayClip
{
    _playClipAllowed = YES;
}

- (void) disallowPlayClip
{
    _playClipAllowed = NO;
}

- (void) enableManager
{
    _playClipAllowed = YES;
    enabled = YES;
    NSInteger enabledDefault = [SoundManager enabledDefaultFromBool:enabled];
    [[NSUserDefaults standardUserDefaults] setInteger:enabledDefault forKey:SOUNDMANAGER_ENABLED_KEY];

    // don't resume looping efects here; it is handled by the screen
    // this gets called either in the frontend options (where there's no looping effects)
    // or in-game pause (where looping effects are paused/resumed by the pause menu);
    
    // resume music
    [self resumeMusic];
    [self resumeMusic2];
}

- (void) disableManager
{
    // pause current music
    [self pauseMusic];
    [self pauseMusic2];

    // don't pause looping efects here; it is handled by the screen
    // this gets called either in the frontend options (where there's no looping effects)
    // or in-game pause (where looping effects are paused/resumed by the pause menu);
    

    enabled = NO;
    NSInteger enabledDefault = [SoundManager enabledDefaultFromBool:enabled];
    [[NSUserDefaults standardUserDefaults] setInteger:enabledDefault forKey:SOUNDMANAGER_ENABLED_KEY];
}

- (void) update
{
    // stop looping effects
    // always stops sounds regardless of whether enabled
    for(SoundClip* cur in curLoopingEffectsStopSet)
    {
        if([curLoopingEffects containsObject:cur])
        {
            [cur stop];
            [curLoopingEffects removeObject:cur];
        }
    }
    
    if(enabled)
    {
        if(resumeLoopingEffects)
        {
            for(SoundClip* cur in curLoopingEffects)
            {
                cur.isLooping = YES;
                //cur.audioPlayer.numberOfLoops = -1;
                [cur play];
            }   
            resumeLoopingEffects = NO;
        }
    
        // play all one-shot effects
        for(NSString* cur in oneShotEffectsStartSet)
        {
            [self playOneShot:cur];
        }
        
        // start looping effects
        for(SoundClip* cur in curLoopingEffectsStartSet)
        {
            cur.isLooping = YES;
            //cur.audioPlayer.numberOfLoops = -1;
            [cur play];
        }
        
        // process music fades
        if((musicFade) && (curBGM2))
        {
            musicFadeCur += musicFadeIncr;
            if(((musicFadeIncr >= 0.0f) && (musicFadeCur >= musicFadeTgt)) ||
               ((musicFadeIncr < 0.0f) && (musicFadeCur <= musicFadeTgt)))
            {
                // stop
                musicFade = NO;
                musicFadeCur = musicFadeTgt;
                if(musicFadingOut)
                {
                    // if music was fading out, stop it
                    [self stopMusic2];
                }
            }
            if(1.0f < musicFadeCur)
            {
                // safeguard our user's ears
                musicFadeCur = 1.0f;
            }
            [curBGM2 setVolume:musicFadeCur];            
        }
    }

    // always updates the start, stop, and active sets
    // the enabled flag only controls actual sounds getting played
    for(SoundClip* cur in curLoopingEffectsStartSet)
    {
        [curLoopingEffects addObject:cur];
    }
    [oneShotEffectsStartSet removeAllObjects];
    [curLoopingEffectsStartSet removeAllObjects];
    [curLoopingEffectsStopSet removeAllObjects];
}

#pragma mark - App Event
- (void) enterBackground
{
    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:SOUNDMANAGER_ENABLED_KEY];
    [self disableManager];
}

- (void) restoreFromBackground
{
    BOOL isEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:SOUNDMANAGER_ENABLED_KEY];
    if(isEnabled)
    {
        [self enableManager];
    }
    else
    {
        [self disableManager];
    }
}

- (void) resignActive
{
    // pause all musics
    [self pauseMusic];
    [self pauseMusic2];
}

- (void) restoreActive
{
    // resume all musics
    [self resumeMusic];
    [self resumeMusic2];
}

#pragma mark - Options Menu 
- (void) toggleSoundOnOff:(id)sender
{
    UISwitch* switchButton = sender;
    if([switchButton isOn])
    {
        [self enableManager];
    }
    else
    {
        [self disableManager];
    }
}

- (void) toggleSound
{
    if([self enabled])
    {
        [self disableManager];
    }
    else
    {
        [self enableManager];
    }
}

#pragma mark -
#pragma mark Private methods

- (void) initGlobalClips
{
	NSBundle* mainBundle = [NSBundle mainBundle];
    
    // One-shot MenuSounds
    [self addOneShotClip:@"Pog_SFX_ArriveHome" fromFile:[mainBundle pathForResource:@"Pog_SFX_ArriveHome" ofType:@"mp3"] defaultVolume:0.6f numAVPlayers:1];
    [self addOneShotClip:@"Pog_SFX_LoadingReady" fromFile:[mainBundle pathForResource:@"Pog_SFX_LoadingReady" ofType:@"mp3"] defaultVolume:0.6f numAVPlayers:1];
    [self addOneShotClip:@"Pog_SFX_Nav_Scroll" fromFile:[mainBundle pathForResource:@"Pog_SFX_Nav_Scroll" ofType:@"mp3"] defaultVolume:0.6f numAVPlayers:4];
    [self addOneShotClip:@"Pog_SFX_Nav_up" fromFile:[mainBundle pathForResource:@"Pog_SFX_Nav_up" ofType:@"mp3"] defaultVolume:0.6f numAVPlayers:1];
    [self addOneShotClip:@"Pog_SFX_Nav_UP_Longer" fromFile:[mainBundle pathForResource:@"Pog_SFX_Nav_UP_Longer" ofType:@"mp3"] defaultVolume:0.6f numAVPlayers:1];
    [self addOneShotClip:@"Pog_SFX_PopUP_Level1" fromFile:[mainBundle pathForResource:@"Pog_SFX_PopUP_Level1" ofType:@"mp3"] defaultVolume:0.6f numAVPlayers:3];
    [self addOneShotClip:@"Pog_SFX_PopUP_Level2" fromFile:[mainBundle pathForResource:@"Pog_SFX_PopUP_Level2" ofType:@"mp3"] defaultVolume:0.6f numAVPlayers:1];
    [self addOneShotClip:@"Pog_SFX_Scanner" fromFile:[mainBundle pathForResource:@"Pog_SFX_Scanner" ofType:@"mp3"] defaultVolume:0.6f numAVPlayers:1];
    [self addOneShotClip:@"Pog_SFX_Select" fromFile:[mainBundle pathForResource:@"Pog_SFX_Select" ofType:@"mp3"] defaultVolume:0.6f numAVPlayers:1];
	
    // Background music/sounds
    [self addClip:@"background_default" fromFile:[mainBundle pathForResource:@"pog_moderate" ofType:@"mp3"]
    defaultVolume:0.10f isLooping:YES];
    [self addClip:@"ambient_wind" fromFile:[mainBundle pathForResource:@"ambient1" ofType:@"m4a"]
    defaultVolume:0.25f isLooping:YES];
//    [self addClip:@"ThunderStorm" fromFile:[mainBundle pathForResource:@"ThunderStorm" ofType:@"m4a"]
//    defaultVolume:0.4f isLooping:YES];
//    [self addClip:@"Seagulls" fromFile:[mainBundle pathForResource:@"Seagulls" ofType:@"m4a"] defaultVolume:0.25f isLooping:YES];
}


// converts the enabled value in UserDefaults to a bool
+ (BOOL) boolFromEnabledDefault:(NSInteger)soundEnabled
{
    BOOL result = YES;
    if(soundEnabled == SOUNDENABLED_NO)
    {
        result = NO;
    }
    return result;
}

// converts an enabled bool to a value to be written to the UserDefaults
+ (NSInteger) enabledDefaultFromBool:(BOOL)soundEnabled
{
    NSInteger result = SOUNDENABLED_YES;
    if(!soundEnabled)
    {
        result = SOUNDENABLED_NO;
    }
    return result;
}

#pragma mark -
#pragma mark Singleton
static SoundManager *singletonSoundManager = nil;

+ (SoundManager*) getInstance
{
	@synchronized(self)
	{
		if (!singletonSoundManager)
		{
			singletonSoundManager = [[SoundManager alloc] init];
		}
	}
	return singletonSoundManager;
}

+ (void) destroyInstance
{
	@synchronized(self)
	{
		singletonSoundManager = nil;
	}
}



@end
