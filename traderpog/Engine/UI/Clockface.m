//
//  Clockface.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 9/6/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "Clockface.h"
#import "AnimMgr.h"
#import <QuartzCore/QuartzCore.h>

static const NSTimeInterval kMinAngularSpeed = M_PI / 1.5f;

@interface Clockface ()
{
    UIImageView* _hourArm;
    UIImageView* _minArm;
    CGAffineTransform _minTransform;
    CGAffineTransform _hourTransform;
}
- (UIImage*) createClockArmWithWidth:(float)width lengthFrac:(float)lengthFrac;
- (void) drawLineForContext:(const CGContextRef)context
                   rectSize:(CGSize)rectSize
                      width:(float)_width
                      angle:(double)_angle
                     length:(double)radius;
@end

@implementation Clockface

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        
        _hourArm = [[UIImageView alloc] initWithFrame:frame];
        [_hourArm setImage:[self createClockArmWithWidth:4.5f lengthFrac:0.65f]];
        [self addSubview:_hourArm];
        
        _minArm = [[UIImageView alloc] initWithFrame:frame];
        [_minArm setImage:[self createClockArmWithWidth:2.5f lengthFrac:0.75f]];
        [self addSubview:_minArm];
        
        _minTransform = CGAffineTransformIdentity;
        _hourTransform = CGAffineTransformIdentity;
    }
    return self;
}

- (void) startAnimating
{
    [[AnimMgr getInstance] addAnimObject:self];
}

- (void) stopAnimating
{
    [[AnimMgr getInstance] removeAnimObject:self];
}

#pragma mark - internal methods

- (UIImage*) createClockArmWithWidth:(float)width lengthFrac:(float)lengthFrac
{
    CGSize imageSize = CGSizeMake(64.0f, 64.0f);
    UIGraphicsBeginImageContext(imageSize);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetRGBStrokeColor(context, 0.0, 0.0, 0.0, 1.0);
    float length = lengthFrac * (imageSize.width / 2.0f);
    [self drawLineForContext:context rectSize:imageSize width:width angle:0.0f length:length];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void) drawLineForContext:(const CGContextRef)context
                   rectSize:(CGSize)rectSize
                      width:(float)_width
                      angle:(double)_angle
                     length:(double)radius
{
    CGPoint c = CGPointMake(rectSize.width/2.0, rectSize.height/2.0);
    
    CGContextSetLineWidth(context, _width);
    CGContextMoveToPoint(context, c.x, c.y);
    CGPoint addLines[] =
    {
        CGPointMake(rectSize.width/2.0, rectSize.height/2.0),
        CGPointMake(radius*cos(_angle) +c.x, radius*sin(_angle) +c.y),
    };
    
    CGContextAddLines(context, addLines, 2);
    CGContextStrokePath(context);
}

#pragma mark - AnimDelegate
- (void) animUpdate:(NSTimeInterval)elapsed
{
    _minTransform = CGAffineTransformRotate(_minTransform, elapsed * kMinAngularSpeed);
    [_minArm setTransform:_minTransform];
    _hourTransform = CGAffineTransformRotate(_hourTransform, elapsed * kMinAngularSpeed / 12.0f);
    [_hourArm setTransform:_hourTransform];
}

@end
