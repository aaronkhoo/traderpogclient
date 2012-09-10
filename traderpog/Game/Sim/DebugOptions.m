//
//  DebugOptions.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 5/3/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "DebugOptions.h"
#import "AFClientManager.h"

static NSString* const keyDebugServerIp = @"serverIp";

@implementation DebugOptions
@synthesize useServer = _useServer;
@synthesize localDev = _localDev;
@synthesize speed100x = _speed100x;

- (id) init
{
    self = [super init];
    if(self)
    {
        _useServer = NO;
        _localDev = NO;
        _speed100x = NO;
        
        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
        NSString* serverIpString = [userDefaults objectForKey:keyDebugServerIp];
        if(serverIpString)
        {
            _serverIp = [NSString stringWithString:serverIpString];
        }
        else 
        {
            _serverIp = @"76.103.214.206";
            [userDefaults setObject:_serverIp forKey:keyDebugServerIp];
        } 
    }
    return self;
}

#pragma mark - setters / getters
- (NSString*) serverIp
{
    return _serverIp;
}

- (void) setServerIp:(NSString *)serverIp
{
    _serverIp = [NSString stringWithString:serverIp];
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:_serverIp forKey:keyDebugServerIp];
    
    [[AFClientManager sharedInstance] resetTraderPogWithIp:_serverIp];
}

#pragma mark - on/off toggles
- (void) setOnOffUseServer:(id)sender
{
    UISwitch* senderSwitch = sender;
    if([senderSwitch isOn])
    {
        _useServer = YES;
    }
    else 
    {
        _useServer = NO;
    }
}

- (void) setOnOffLocalDev:(id)sender
{
    UISwitch* senderSwitch = sender;
    if([senderSwitch isOn])
    {
        _localDev = YES;
        NSLog(@"localDev ON");
    }
    else
    {
        _localDev = NO;
        NSLog(@"localDev OFF");
    }
}

- (void) setOnOffSpeed100x:(id)sender
{
    UISwitch* senderSwitch = sender;
    if([senderSwitch isOn])
    {
        _speed100x = YES;
    }
    else
    {
        _speed100x = NO;
    }
}

#pragma mark - Singleton
static DebugOptions* singleton = nil;
+ (DebugOptions*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
			singleton = [[DebugOptions alloc] init];
		}
	}
	return singleton;
}

+ (void) destroyInstance
{
	@synchronized(self)
	{
		singleton = nil;
	}
}

@end
