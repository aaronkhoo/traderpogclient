//
//  KnobSlice.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/6/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "KnobSlice.h"
#import <QuartzCore/QuartzCore.h>

@interface KnobSlice ()
{
    UIView* _contentContainer;
    UILabel* _contentLabel;
}
@end

@implementation KnobSlice
@synthesize view = _view;
@synthesize minAngle = _minAngle;
@synthesize midAngle = _midAngle;
@synthesize maxAngle = _maxAngle;

- (id) initWithMin:(float)min mid:(float)mid max:(float)max 
            radius:(float)radius angle:(float)angle
             index:(unsigned int)index
{
    self = [super init];
    if(self)
    {
        _minAngle = min;
        _midAngle = mid;
        _maxAngle = max;
        _radius = radius;
        
        // create slice view
        CGRect viewRect = CGRectMake(0.0f, 0.0f, _radius, 40.0f);
        UIView* newView = [[UIView alloc] initWithFrame:viewRect];
        newView.backgroundColor = [UIColor clearColor];
        newView.layer.anchorPoint = CGPointMake(1.0f, 0.5f);
        
        // view-layer's position is expressed in its super-layer's coordinate system
        // which is the center of the wheel
        newView.layer.position = CGPointMake(_radius, _radius);
        
        // transform starts at negative x-axis and rotates counter-clockwise;
        // that's why it's angle is opposite of the mid,min,max logical angles
        newView.transform = CGAffineTransformMakeRotation(angle * index);
        
        _view = newView;   
        
        // create content-container that is attached to the outer edge of the container and oriented
        // such that it is horizontal when the container view is pointing up
        CGRect contentRect = CGRectMake(0.0f, 0.0f, _radius, 40.0f);
        UIView* newContainer = [[UIView alloc] initWithFrame:contentRect];
        newContainer.layer.position = CGPointMake(contentRect.size.width * 0.4f, contentRect.size.height * 0.5f);
        newContainer.backgroundColor = [UIColor clearColor];
        CGAffineTransform contentTransform = CGAffineTransformMakeRotation(-M_PI_2);
        newContainer.transform = contentTransform;
        [_view addSubview:newContainer];
        _contentContainer = newContainer;
        
        UILabel* sliceLabel = [[UILabel alloc] initWithFrame:contentRect];
        [sliceLabel setTextAlignment:UITextAlignmentCenter];
        [sliceLabel setFont:[UIFont fontWithName:@"Marker Felt" size:20.0f]];
        [sliceLabel setBackgroundColor:[UIColor clearColor]];
        [sliceLabel setTextColor:[UIColor whiteColor]];
        [_contentContainer addSubview:sliceLabel];
        _contentLabel = sliceLabel;
    }
    return self;
}

- (void) setText:(NSString *)text
{
    [_contentLabel setText:text];
}


@end
