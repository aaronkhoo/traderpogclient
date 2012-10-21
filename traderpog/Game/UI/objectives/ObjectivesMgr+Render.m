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
#import "PointObjective.h"
#import "PogUIUtility.h"

@implementation ObjectivesMgr (Render)
- (BOOL) updateGameViewController:(GameViewController *)game
{
    BOOL addedNew = NO;
    
    GameObjective* next = [self getNextObjective];
    if(next && ![self outObjective])
    {
        switch ([next type])
        {
            case kGameObjectiveType_Scan:
                //[self showScanObjective:next inGame:game];
                self.outObjective = next;
                addedNew = YES;
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
    else if([self outObjective])
    {
        addedNew = YES;
    }
    return addedNew;
}

#pragma mark - internals
- (UIViewController*) controllerForBasic:(GameObjective *)objective
{
    BasicObjectiveUI* screen = [[BasicObjectiveUI alloc] initWithGameObjective:objective];
    
    return screen;
}

- (void) showScanObjective:(GameObjective*)objective inGame:(GameViewController*)game
{
    PointObjective* popup = (PointObjective*)[game dequeueModalViewWithIdentifier:kPointObjectiveViewReuseIdentifier];
    if(!popup)
    {
        UIView* parent = [game view];
        popup = [[PointObjective alloc] initWithGameObjective:objective];
        CGRect popFrame = [PogUIUtility createCenterFrameWithSize:popup.nibContentView.bounds.size
                                                          inFrame:parent.bounds
                                                    withFrameSize:popup.nibView.bounds.size];
        //popFrame.origin.y += kAccelViewYOffset;
        [popup setFrame:popFrame];
    }
    
    // show it
    [game showModalView:popup animated:NO];
}

@end
