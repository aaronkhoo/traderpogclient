//
//  MapProtocols.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/15/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@protocol MapAnnotationProtocol <NSObject>
- (MKAnnotationView*) annotationViewInMap:(MKMapView*)mapView;
@end

@protocol MapAnnotationViewProtocol<NSObject>
- (void) didSelectAnnotationViewInMap:(MKMapView*)mapView;
- (void) didDeselectAnnotationViewInMap:(MKMapView*)mapView;
@end