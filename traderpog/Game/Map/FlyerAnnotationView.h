//
//  FlyerAnnotationView.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/22/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MapProtocols.h"

extern NSString* const kFlyerAnnotationViewReuseId;
@class FlyerAnnotation;
@interface FlyerAnnotationView : MKAnnotationView<MapAnnotationViewProtocol>

- (id) initWithAnnotation:(FlyerAnnotation*)annotation;
@end
