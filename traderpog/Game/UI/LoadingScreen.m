//
//  LoadingScreen.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "LoadingScreen.h"
#import "GameColors.h"
#import "ImageManager.h"
#import "LoadingCircle.h"

static const float kRotationSpeed = M_PI * 1.4f;
static const NSInteger kDisplayLinkFrameInterval = 1;
static const CFTimeInterval kDisplayLinkMaxFrametime = 1.0 / 20.0;

@interface LoadingScreen ()
{
    LoadingCircle* _loadingCircle;
}
- (void) initBackgroundColor;
- (void) initCircle;
@end

@implementation LoadingScreen
@synthesize bigLabel = _bigLabel;
@synthesize progressLabel = _progressLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) 
    {
    }
    return self;
}

- (void) dealloc
{
    NSLog(@"LoadingScreen dealloc");
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initBackgroundColor];
    [self initCircle];
    [_loadingCircle showAnimated:YES afterDelay:0.2f];
    [_bigLabel setHidden:NO];
    [_progressLabel setHidden:NO];
}

- (void)viewDidUnload
{
    [_loadingCircle hideAnimated:NO completion:nil];
    _bigLabel = nil;
    _progressLabel = nil;
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) dismissWithCompletion:(LoadingDismissCompletion)completion
{
    [_bigLabel setHidden:YES];
    [_progressLabel setHidden:YES];
    [_loadingCircle hideAnimated:YES
                      completion:^(void){
                          if(completion)
                          {
                              completion();
                          }
                      }];
}

#pragma mark - internal methods
- (void) initBackgroundColor
{
    // hexcolor is ED 1C 24
    [self.view setBackgroundColor:[UIColor colorWithRed:237.0f/255.0f green:28.0f/255.0f blue:36.0f/255.0f alpha:1.0f]];
}

- (void) initCircle
{
    UIColor* circleColor = [GameColors bubbleColorScanWithAlpha:1.0f];
    UIColor* borderColor = [GameColors borderColorScanWithAlpha:1.0f];
    UIImage* yunImage = [[ImageManager getInstance] getImage:@"icon_yun.png"
                                               fallbackNamed:@"icon_yun.png"
                                                   withColor:[GameColors bubbleColorScanWithAlpha:1.0f]];
    UIImage* flyerImage = [[ImageManager getInstance] getImage:@"flyer.png" fallbackNamed:@"flyer.png"];
    _loadingCircle = [[LoadingCircle alloc] initWithFrame:self.view.bounds color:circleColor borderColor:borderColor decalImage:yunImage rotateIcon:flyerImage visibleFraction:0.8f];
    [self.view addSubview:_loadingCircle];
    
    [_loadingCircle startAnim];
}
@end
