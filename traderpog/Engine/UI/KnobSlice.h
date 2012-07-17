//
//  KnobSlice.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/6/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KnobSlice : NSObject
{
    float _minAngle;
    float _midAngle;
    float _maxAngle;
    float _radius;
    UIView* _view;
}
@property (nonatomic,strong) UIView* view;
@property (nonatomic,assign) float minAngle;
@property (nonatomic,assign) float midAngle;
@property (nonatomic,assign) float maxAngle;

- (id) initWithMin:(float)min mid:(float)mid max:(float)max 
            radius:(float)radius angle:(float)angle
             index:(unsigned int)index;
- (void) setContent:(UIView*)view;

@end
