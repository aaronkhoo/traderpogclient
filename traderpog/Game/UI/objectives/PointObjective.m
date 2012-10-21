//
//  PointObjective.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/21/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "PointObjective.h"
#import "PogUIUtility.h"
#import "GameColors.h"

NSString* const kPointObjectiveViewReuseIdentifier = @"PointObjective";
static const float kBorderWidth = 6.0f;
static const float kBuyCircleBorderWidth = 6.0f;
static const float kBorderCornerRadius = 8.0f;

@interface PointObjective ()
{
    GameObjective* _gameObjective;
}
@end

@implementation PointObjective

- (id)initWithGameObjective:(GameObjective *)objective
{
    self = [super initWithFrame:CGRectMake(0.0f, 0.0f, 0.0f, 0.0f)];
    if (self)
    {
        [[NSBundle mainBundle] loadNibNamed:@"PointObjective" owner:self options:nil];
        [self addSubview:self.nibView];

        [PogUIUtility setBorderOnView:self.nibContentView
                                width:kBorderWidth
                                color:[GameColors borderColorPostsWithAlpha:1.0f]
                         cornerRadius:kBorderCornerRadius];
        [self.nibContentView setBackgroundColor:[GameColors bubbleColorScanWithAlpha:1.0f]];
    }
    return self;
}

- (void) dealloc
{
    NSLog(@"dealloc PointObjective");
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/


#pragma mark - ViewReuseDelegate
- (NSString*) reuseIdentifier
{
    return kPointObjectiveViewReuseIdentifier;
}

- (void) prepareForQueue
{
}


@end
