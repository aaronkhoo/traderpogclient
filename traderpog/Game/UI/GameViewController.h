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
#import "KnobProtocol.h"

@class MKMapView;
@class MapControl;
@interface GameViewController : UIViewController<KnobProtocol>
{
    MapControl* _mapControl;
    GADBannerView* _bannerView;
}
@property (nonatomic, strong) MapControl* mapControl;
@property (nonatomic) CLLocationCoordinate2D coord;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIButton *debugButton;

- (id) init;
- (id) initAtCoordinate:(CLLocationCoordinate2D)coord;
- (void) showKnobAnimated:(BOOL)isAnimated delay:(NSTimeInterval)delay;
- (void) dismissKnobAnimated:(BOOL)isAnimated;
- (void) showPostWheelAnimated:(BOOL)isAnimated;
- (void) showFlyerWheelAnimated:(BOOL)isAnimated;
- (IBAction)didPressDebug:(id)sender;

- (BOOL) isHeldHudCoinsUpdate;
- (void) setHoldHudCoinsUpdate:(BOOL)shouldHold;
@end
