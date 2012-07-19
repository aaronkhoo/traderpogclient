//
//  GameViewController.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@class MKMapView;
@class MapControl;
@interface GameViewController : UIViewController
{
    MapControl* _mapControl;
}
@property (nonatomic, strong) MapControl* mapControl;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

- (id) initAtCoordinate:(CLLocationCoordinate2D)coord;
- (void) showKnobAnimated:(BOOL)isAnimated delay:(NSTimeInterval)delay;
- (void) dismissKnobAnimated:(BOOL)isAnimated;
@end
