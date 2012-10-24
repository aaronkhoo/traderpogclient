//
//  GameViewController.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "GADBannerView.h"
#import "GADBannerViewDelegate.h"
#import "KnobProtocol.h"
#import "ModalNavDelegate.h"
#import "ModalNavControl.h"

enum kGameViewModalFlags
{
    kGameViewModalFlag_None = 0,
    kGameViewModalFlag_KeepKnob = (1 << 0),         // don't dismiss the knob
    kGameViewModalFlag_KeepInfoCircle = (1 << 1),   // don't hide Info button
    kGameViewModalFlag_NoGameEvent = (1 << 2),      // don't dequeue game-event when modal is up
    kGameViewModalFlag_Objective = (1 << 3)         // this is an objective message
};

enum kKnobSlices
{
    kKnobSliceScan = 0,
    kKnobSliceFlyer,
    kKnobSliceBeacon,
    kKnobSlicePost,
    
    kKnobSliceNum
};

@class MKMapView;
@class MapControl;
@class ViewReuseQueue;
@class GameHud;
@class MyTradePost;
@class Flyer;
@interface GameViewController : UIViewController<KnobProtocol, GADBannerViewDelegate, ModalNavDelegate>
{
    MapControl* _mapControl;
    GADBannerView* _bannerView;
    GameHud* _hud;

    // modal view
    ViewReuseQueue* _reusableModals;
    UIView* _modalView;
    unsigned int _modalFlags;
    ModalNavControl* _modalNav;
}
@property (nonatomic, strong) MapControl* mapControl;
@property (nonatomic,strong) GameHud* hud;
@property (nonatomic) CLLocationCoordinate2D coord;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic,readonly) unsigned int modalFlags;
@property (nonatomic,strong) ModalNavControl* modalNav;

- (id) init;
- (id) initAtCoordinate:(CLLocationCoordinate2D)coord;
- (void) teardown;
- (void) disableMap;
- (void) enableMap;

// knob and wheel
- (void) showKnobAnimated:(BOOL)isAnimated delay:(NSTimeInterval)delay;
- (void) dismissKnobAnimated:(BOOL)isAnimated;
- (void) showPostWheelAnimated:(BOOL)isAnimated;
- (void) showFlyerWheelAnimated:(BOOL)isAnimated;
- (void) setBeaconWheelText:(NSString*)new_text;
- (void) dismissActiveWheelAnimated:(BOOL)isAnimated;
- (void) lockKnobAtSlice:(unsigned int)sliceIndex;
- (void) unlockKnob;
- (void) disableKnobButton;
- (void) enableKnobButton;

// modal ui
- (UIView*) dequeueModalViewWithIdentifier:(NSString*)identifier;
- (void) showModalView:(UIView *)view options:(unsigned int)options animated:(BOOL)isAnimated;
- (void) showModalView:(UIView*)view animated:(BOOL)isAnimated;
- (void) closeModalViewAnimated:(BOOL)isAnimated;
- (void) showModalNavViewController:(UIViewController*)controller
                         completion:(ModalNavCompletionBlock)completion;
- (void) dismissInfo;
- (void) showMyPostMenuForPost:(MyTradePost*)myPost;
- (void) dismissMyPostMenuAnimated:(BOOL)isAnimated;
- (void) showInfoViewForFlyer:(Flyer*)flyer;


// game-state driven display update
- (BOOL) isHeldHudCoinsUpdate;
- (void) setHoldHudCoinsUpdate:(BOOL)shouldHold;

- (IBAction)didPressPop:(id)sender;


@end
