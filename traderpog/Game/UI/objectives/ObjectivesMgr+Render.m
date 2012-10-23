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
#import "GameManager.h"

@implementation ObjectivesMgr (Render)
- (BOOL) updateGameViewController:(GameViewController *)game
{
    [self checkCompletion];
    if(![self outObjective])
    {
        GameObjective* next = [self getNextObjective];
        if(next)
        {
            switch ([next type])
            {
                case kGameObjectiveType_Scan:
                    [self showScanObjective:next inGame:game];
                    self.outObjective = next;
                    break;
                    
                case kGameObjectiveType_KnobLeft:
                case kGameObjectiveType_KnobRight:
                    if([self shouldTriggerKnobObjective])
                    {
                        [self showKnobLeftRightObjective:next inGame:game];
                        self.outObjective = next;
                    }
                    break;
                    
                default:
                case kGameObjectiveType_Basic:
                {
                    UIViewController* basicUI = [self controllerForBasic:next];
                    [game showModalNavViewController:basicUI completion:nil];
                    self.outObjective = next;
                }
                    break;
            }
        }
    }
    
    BOOL hasOutstanding = NO;
    if([self outObjective])
    {
        hasOutstanding = YES;
    }
    return hasOutstanding;
}

- (void) dismissOutObjectiveView
{
    if([self outObjective])
    {
        switch([self.outObjective type])
        {
            case kGameObjectiveType_KnobLeft:
            case kGameObjectiveType_KnobRight:
                [self dismissKnobLeftRightObjective:[self outObjective] inGame:[[GameManager getInstance] gameViewController]];
                break;
            case kGameObjectiveType_Scan:
                [self dismissScanObjective:[self outObjective] inGame:[[GameManager getInstance] gameViewController]];
                break;
                
            case kGameObjectiveType_Basic:
            default:
                // do nothing; this view type uses modalNav and dismisses itself
                break;
        }
    }
}

#pragma mark - internals
- (UIViewController*) controllerForBasic:(GameObjective *)objective
{
    BasicObjectiveUI* screen = [[BasicObjectiveUI alloc] initWithGameObjective:objective];
    
    return screen;
}


- (void) setupPointObjective:(PointObjective*)view
            forGameObjective:(GameObjective*)objective
                      inGame:(GameViewController*)game
{
    // desc
    NSString* myNewLineStr = @"\n";
    NSString* newDesc = [[self descForObjective:objective] stringByReplacingOccurrencesOfString:@"\\n" withString:myNewLineStr];
    [view.descLabel setText:newDesc];
    [view.descLabel sizeToFit];
    
    // point
    CGPoint frac = [self pointForObjective:objective];
    CGSize screenSize = game.view.bounds.size;
    view.screenPoint = CGPointMake(frac.x * screenSize.width, frac.y * screenSize.height);
    
    // disable user interaction on point-objective views so that the player can
    // click through it onto buttons that they need to click to proceed (like the Scan button)
    [view setUserInteractionEnabled:NO];
}

- (void) showScanObjective:(GameObjective*)objective inGame:(GameViewController*)game
{
    PointObjective* popup = (PointObjective*)[game dequeueModalViewWithIdentifier:kPointObjectiveViewReuseIdentifier];
    if(!popup)
    {
        UIView* parent = [game view];
        popup = [[PointObjective alloc] initWithGameObjective:objective];
        CGRect popFrame = [PogUIUtility createCenterFrameWithSize:popup.nibView.bounds.size
                                                          inFrame:parent.bounds
                                                    withFrameSize:popup.nibView.bounds.size];
        //popFrame.origin.y += kAccelViewYOffset;
        [popup setFrame:popFrame];
    }
    
    // setup the content of the view
    [self setupPointObjective:popup forGameObjective:objective inGame:game];
    
    // show it
    [game showModalView:popup
                options:(kGameViewModalFlag_KeepKnob|kGameViewModalFlag_Objective)
               animated:NO];
    
    [game lockKnobAtSlice:kKnobSliceScan];
}

- (void) dismissScanObjective:(GameObjective*)objective inGame:(GameViewController*)game
{
    if([game modalFlags] & kGameViewModalFlag_Objective)
    {
        [game closeModalViewAnimated:NO];
    }
    [game unlockKnob];
}

- (void) showKnobLeftRightObjective:(GameObjective*)objective inGame:(GameViewController*)game
{
    PointObjective* popup = (PointObjective*)[game dequeueModalViewWithIdentifier:kPointObjectiveViewReuseIdentifier];
    if(!popup)
    {
        UIView* parent = [game view];
        popup = [[PointObjective alloc] initWithGameObjective:objective];
        CGRect popFrame = [PogUIUtility createCenterFrameWithSize:popup.nibView.bounds.size
                                                          inFrame:parent.bounds
                                                    withFrameSize:popup.nibView.bounds.size];
        //popFrame.origin.y += kAccelViewYOffset;
        [popup setFrame:popFrame];
    }
    
    // setup the content of the view
    [self setupPointObjective:popup forGameObjective:objective inGame:game];
    
    // show it
    [game showModalView:popup
                options:(kGameViewModalFlag_KeepKnob|kGameViewModalFlag_Objective)
               animated:NO];
    
    // disable knob button; user is only allowed to rotate on knob under this objective;
    [game disableKnobButton];
}

- (void) dismissKnobLeftRightObjective:(GameObjective*)objective inGame:(GameViewController*)game
{
    if([game modalFlags] & kGameViewModalFlag_Objective)
    {
        [game closeModalViewAnimated:NO];        
    }
    [game enableKnobButton];
}

- (BOOL) shouldTriggerKnobObjective
{
    BOOL result = NO;
    if([self homeNotVisibleCount] &&
       ((![self knobLeftCount]) || (![self knobRightCount])))
    {
        result = YES;
    }
    return result;
}

- (void) checkCompletion
{
    if([self outObjective])
    {
        GameObjective* cur = [self outObjective];
        switch([cur type])
        {
            case kGameObjectiveType_Scan:
                if([self scanCount])
                {
                    [self setCompletedForObjective:cur];
                }
                break;
                
            case kGameObjectiveType_KnobLeft:
                if([self knobLeftCount])
                {
                    [self setCompletedForObjective:cur];
                }
                break;
                
            case kGameObjectiveType_KnobRight:
                if([self knobRightCount])
                {
                    [self setCompletedForObjective:cur];
                }
                break;
                
            case kGameObjectiveType_Basic:
            default:
                // do nothing; completion checked outside of this loop
                break;
        }
    }
}


// this function restores all the modifications that had been set
// on GameViewController for Objective-displays
// call this function when outObjective goes from non-nil to nil;
- (void) restoreToNormalGame:(GameViewController*)game
{
    
}

@end
