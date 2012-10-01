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
@interface FlyerAnnotationView : MKAnnotationView<MapAnnotationViewProtocol>
{
    UIImageView* _imageView;            // oriented image
    UIImageView* _imageViewIdentity;    // normal non-oriented image
}
@property (nonatomic,strong) UIImageView* imageView;
@property (nonatomic,strong) UIImageView* imageViewIdentity;
- (id) initWithAnnotation:(NSObject<MKAnnotation>*)annotation;
- (void) setRenderTransformWithAngle:(float)angle;
- (void) showCountdown:(BOOL)yesNo;

- (void) setOrientedImage:(UIImage*)image;
- (void) setImage:(UIImage*)image;
@end
