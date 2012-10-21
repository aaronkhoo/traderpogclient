//
//  ObjectivesMgr.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/21/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "ObjectivesMgr.h"
#import "GameManager.h"

static NSString* const kObjectivesMgrFilename = @"objectives.sav";
static NSString* const kKeyObjectives = @"objectives";

@interface ObjectivesMgr ()
{
    NSUInteger _nextIndex;
}
- (void) updateNextIndex;
@end

@implementation ObjectivesMgr

- (id) init
{
    self = [super init];
    if(self)
    {
        NSString* filepath = [[NSBundle mainBundle] pathForResource:@"gameobjectives" ofType:@"plist"];
        NSArray* plistArray = [NSArray arrayWithContentsOfFile:filepath];
        
        _objectives = [NSMutableArray arrayWithCapacity:[plistArray count]];
        for(NSDictionary* cur in plistArray)
        {
            GameObjective* newObjective = [[GameObjective alloc] initWithDictionary:cur];
            [_objectives addObject:newObjective];
        }
        
        _nextIndex = 0;
    }
    return self;
}

#pragma mark - next objective

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
    [objective setCompleted];
    [self updateNextIndex];
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
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    _objectives = [aDecoder decodeObjectForKey:kKeyObjectives];
    
    
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
