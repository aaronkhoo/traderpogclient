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
#import "GameViewController.h"

@implementation ObjectivesMgr (Render)
- (BOOL) updateGameViewController:(GameViewController *)game
{
    BOOL addedNew = NO;
    
    GameObjective* next = [self getNextObjective];
    if(next)
    {
        switch ([next type])
        {
            case kGameObjectiveType_Scan:
                break;
                
            default:
            case kGameObjectiveType_Basic:
            {
                UIViewController* basicUI = [self controllerForBasic:next];
                [game showModalNavViewController:basicUI completion:nil];
                addedNew = YES;
            }
                break;
        }
    }
    return addedNew;
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
