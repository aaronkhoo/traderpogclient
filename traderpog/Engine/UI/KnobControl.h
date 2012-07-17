//
//  KnobControl.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/6/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KnobControl : UIControl
{
    UIView*      _container;
    unsigned int _numSlices;
    NSMutableArray* _slices;
    unsigned int _selectedSlice;
}

@property (nonatomic,strong) UIView* container;
@property (nonatomic,assign) unsigned int numSlices;
@property (nonatomic,strong) NSMutableArray* slices;
@property (nonatomic,assign) unsigned int selectedSlice;
@property (nonatomic,strong) UIButton* activateButton;

- (id)initWithFrame:(CGRect)frame 
          numSlices:(unsigned int)numSlices;

@end
