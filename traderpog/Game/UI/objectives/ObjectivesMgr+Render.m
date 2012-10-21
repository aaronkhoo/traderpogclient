//
//  ObjectivesMgr+Render.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/21/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "ObjectivesMgr+Render.h"
#import "ObjectivesMgr.h"
#import "BasicObjectiveUI.h"

@implementation ObjectivesMgr (Render)
- (UIViewController*) update
{
    UIViewController* result = nil;
    
    GameObjective* next = [self getNextObjective];
    if(next)
    {
        switch ([next type])
        {
            case kGameObjectiveType_Scan:
                result = [self controllerForScan:next];
                break;
                
            default:
            case kGameObjectiveType_Basic:
                result = [self controllerForBasic:next];
                break;
        }
    }
    return result;
}

#pragma mark - internals
- (UIViewController*) controllerForBasic:(GameObjective *)objective
{
    BasicObjectiveUI* screen = [[BasicObjectiveUI alloc] initWithGameObjective:objective];
    
    return screen;
}

- (UIViewController*) controllerForScan:(GameObjective*)objective
{
    return nil;
}

@end
