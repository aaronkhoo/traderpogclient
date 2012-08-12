//
//  BeaconAnnotationView.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/11/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MapProtocols.h"

extern NSString* const kBeaconAnnotationViewReuseId;
@interface BeaconAnnotationView : MKAnnotationView<MapAnnotationViewProtocol>
- (id) initWithAnnotation:(NSObject<MKAnnotation>*)annotation;
@end

