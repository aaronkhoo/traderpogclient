//
//  GameHud.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 9/5/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CircleBarView;
@interface GameHud : UIView
{
    CircleBarView* _coins;
}
@property (nonatomic,strong) CircleBarView* coins;
@end
