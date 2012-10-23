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
        
        _screenPoint = CGPointMake(0.5f, 0.5f);
        [self setBackgroundColor:[UIColor clearColor]];
    }
    return self;
}

- (void) dealloc
{
    NSLog(@"dealloc PointObjective");
}

static const float kTriangleWidth = 20.0f;
static const float kTriangleHeight = 80.0f;
- (void)drawRect:(CGRect)rect
{
    NSLog(@"rect is (%f, %f, %f, %f)", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    CGRect contentFrame = self.nibContentView.frame;
    CGPoint contentMidBot = CGPointMake(contentFrame.origin.x + (0.5f * contentFrame.size.width),
                                        contentFrame.origin.y + (1.0f * contentFrame.size.height));
    UIColor* triColor = [GameColors borderColorPostsWithAlpha:1.0f];
    
    
	CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, contentMidBot.x - kTriangleWidth, contentMidBot.y);
    CGPathAddLineToPoint(path, NULL, _screenPoint.x, _screenPoint.y);
    CGPathAddLineToPoint(path, NULL, contentMidBot.x + kTriangleWidth, contentMidBot.y);
    CGPathCloseSubpath(path);
    
    // draw triangle
	CGContextRef context = UIGraphicsGetCurrentContext();
	[triColor setFill];
	CGContextAddPath(context, path);
	CGContextSaveGState(context);
	CGContextFillPath(context);
	CGContextRestoreGState(context);
    
    CGPathRelease(path);
}

#pragma mark - getters/setters
- (CGPoint) screenPoint
{
    return _screenPoint;
}

- (void) setScreenPoint:(CGPoint)screenPoint
{
    CGRect myFrame = self.frame;
    _screenPoint = CGPointMake(screenPoint.x - myFrame.origin.x,
                               screenPoint.y - myFrame.origin.y);
    
    // adjust my frame's height sufficiently to fit screenPoint inside it
    CGRect newFrame = self.frame;
    float ydiff = _screenPoint.y;
    if(ydiff <= newFrame.size.height)
    {
        // do nothing
    }
    else
    {
        // expand the frame by the amount y is outside by
        newFrame.size = CGSizeMake(newFrame.size.width, ydiff);
        [self setFrame:newFrame];
    }
    [self setNeedsDisplay];
}

#pragma mark - ViewReuseDelegate
- (NSString*) reuseIdentifier
{
    return kPointObjectiveViewReuseIdentifier;
}

- (void) prepareForQueue
{
}


@end
