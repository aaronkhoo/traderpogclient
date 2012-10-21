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
        BasicObjectiveUI* screen = [[BasicObjectiveUI alloc] initWithGameObjective:next];
        result = screen;
    }
    return result;
}
@end
