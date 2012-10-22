//
//  ObjectivesMgr.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/21/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "ObjectivesMgr.h"
#import "ObjectivesMgr+Render.h"
#import "GameManager.h"

static NSString* const kObjectivesMgrFilename = @"objectives.sav";
static NSString* const kKeyObjectives = @"objectives";
static NSString* const kKeyVersion = @"version";

static NSString* const kObjectivesMgrFileVersion = @"0.1";

@interface ObjectivesMgr ()
{
    NSUInteger _nextIndex;
    
    NSMutableDictionary* _registry;
}
- (void) updateNextIndex;
@end

@implementation ObjectivesMgr
@synthesize outObjective = _outObjective;
@synthesize fileversion = _fileversion;

- (id) init
{
    self = [super init];
    if(self)
    {
        NSString* filepath = [[NSBundle mainBundle] pathForResource:@"gameobjectives" ofType:@"plist"];
        NSArray* plistArray = [NSArray arrayWithContentsOfFile:filepath];
        
        _registry = [NSMutableDictionary dictionaryWithCapacity:[plistArray count]];
        _objectives = [NSMutableArray arrayWithCapacity:[plistArray count]];
        for(NSDictionary* cur in plistArray)
        {
            // GameObjective tracking array
            GameObjective* newObjective = [[GameObjective alloc] initWithDictionary:cur];
            [_objectives addObject:newObjective];
            
            // registry for objective info (like imagename, desc, etc.)
            [_registry setObject:cur forKey:[cur objectForKey:kKeyGameObjId]];
        }
        _fileversion = [NSString stringWithString:kObjectivesMgrFileVersion];
        _nextIndex = 0;
        _outObjective = nil;
    }
    return self;
}

#pragma mark - objective operations

- (GameObjective*) getNextObjective
{
    GameObjective* result = nil;
    
    if(_nextIndex < [_objectives count])
    {
        result = [_objectives objectAtIndex:_nextIndex];
    }
    
    return result;
}

- (void) setCompletedForObjective:(GameObjective *)objective
{
    // dismiss any objective view
    [self dismissOutObjectiveView];

    // mark objective as completed
    [objective setCompleted];
    
    // clear outstanding objective field
    self.outObjective = nil;
    
    // update the next index
    [self updateNextIndex];
}

- (NSString* const) descForObjective:(GameObjective *)objective
{
    NSDictionary* lookup = [_registry objectForKey:[objective objectiveId]];
    NSString* result = [lookup objectForKey:kKeyGameObjDesc];
    return result;
}

- (NSString* const) imageNameForObjective:(GameObjective *)objective
{
    NSDictionary* lookup = [_registry objectForKey:[objective objectiveId]];
    NSString* result = [lookup objectForKey:kKeyGameObjImage];
    return result;    
}

#pragma mark - user events or actions
- (void) playerDidPerformScan
{
    if([self outObjective])
    {
        if([self.outObjective type] == kGameObjectiveType_Scan)
        {
            // mark this objective as completed
            [self setCompletedForObjective:[self outObjective]];
        }
    }
}


#pragma mark - internal

// update the _nextIndex to point to the next incomplete objective
// internally called when objective completion is set
- (void) updateNextIndex
{
    NSUInteger index = 0;
    for(GameObjective* cur in _objectives)
    {
        if(![cur isCompleted])
        {
            break;
        }
        ++index;
    }
    _nextIndex = index;    
}


#pragma mark - NSCoding
- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_objectives forKey:kKeyObjectives];
    [aCoder encodeObject:_fileversion forKey:kKeyVersion];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    _objectives = [aDecoder decodeObjectForKey:kKeyObjectives];
    _fileversion = [aDecoder decodeObjectForKey:kKeyVersion];
    
    // load up registry
    NSString* filepath = [[NSBundle mainBundle] pathForResource:@"gameobjectives" ofType:@"plist"];
    NSArray* plistArray = [NSArray arrayWithContentsOfFile:filepath];
    _registry = [NSMutableDictionary dictionaryWithCapacity:[plistArray count]];
    for(NSDictionary* cur in plistArray)
    {
        [_registry setObject:cur forKey:[cur objectForKey:kKeyGameObjId]];
    }
    
    [self updateNextIndex];
    _outObjective = nil;

    return self;
}


#pragma mark - saved game data loading and unloading
+ (NSString*) objectivesFilepath
{
    NSString* docsDir = [GameManager documentsDirectory];
    NSString* filepath = [docsDir stringByAppendingPathComponent:kObjectivesMgrFilename];
    return filepath;
}

+ (ObjectivesMgr*) loadObjectivesData
{
    ObjectivesMgr* current_mgr = nil;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* filepath = [ObjectivesMgr objectivesFilepath];
    if ([fileManager fileExistsAtPath:filepath])
    {
        NSData* readData = [NSData dataWithContentsOfFile:filepath];
        if(readData)
        {
            current_mgr = [NSKeyedUnarchiver unarchiveObjectWithData:readData];
            
            if(![kObjectivesMgrFileVersion isEqualToString:[current_mgr fileversion]])
            {
                // if version doesn't match, remove the data file so that it gets re-created
                [current_mgr removeObjectivesData];
                current_mgr = nil;
            }
        }
    }
    return current_mgr;
}

- (void) saveObjectivesData
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
    NSError* error = nil;
    BOOL writeSuccess = [data writeToFile:[ObjectivesMgr objectivesFilepath]
                                  options:NSDataWritingAtomic
                                    error:&error];
    if(writeSuccess)
    {
        NSLog(@"objectives file saved successfully");
    }
    else
    {
        NSLog(@"objectives file save failed: %@", error);
    }
}

- (void) removeObjectivesData
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* filepath = [ObjectivesMgr objectivesFilepath];
    NSError *error = nil;
    if ([fileManager fileExistsAtPath:filepath])
    {
        [fileManager removeItemAtPath:filepath error:&error];
    }
}



#pragma mark - Singleton
static ObjectivesMgr* singleton = nil;
+ (ObjectivesMgr*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
            // First, try to load data from disk
            singleton = [ObjectivesMgr loadObjectivesData];
            if (!singleton)
            {
                // if not yet created, start new
                singleton = [[ObjectivesMgr alloc] init];
            }
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
