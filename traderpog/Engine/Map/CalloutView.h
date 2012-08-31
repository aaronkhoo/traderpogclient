//
//  CalloutView.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/30/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//
//  This is a minimal version of the CalloutAnnotationView class, which is based on the work at
//  http://stackoverflow.com/questions/6392931/mkannotationview-lock-custom-annotation-view-to-pin-on-location-updates
//  http://blog.asolutions.com/2010/09/building-custom-map-annotation-callouts-part-1/
//  


#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "MapProtocols.h"

@interface CalloutView : MKAnnotationView<MapAnnotationViewProtocol>
{
    CGRect _contentFrame;
    CGRect _originalFrame;
	MKAnnotationView *_parentAnnotationView;
	MKMapView *_mapView;
	CGRect _endFrame;
	UIView *_contentView;
	CGFloat _yShadowOffset;
	CGPoint _offsetFromParent;
	CGFloat _contentHeight;
    BOOL    _isModal;
}
@property (nonatomic) CGRect contentFrame;
@property (nonatomic) CGRect originalFrame;
@property (nonatomic, strong) MKAnnotationView *parentAnnotationView;
@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) IBOutlet UIView *contentView;

- (void)animateIn;
- (void)animateInStepTwo;
- (void)animateInStepThree;
- (void)setAnnotationAndAdjustMap:(id <MKAnnotation>)annotation;
- (id)initWithAnnotation:(id<MKAnnotation>)annotation;

@end
