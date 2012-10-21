//
//  BasicObjectiveUI.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 10/21/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "BasicObjectiveUI.h"
#import "PogUIUtility.h"
#import "GameColors.h"
#import "UINavigationController+Pog.h"
#import "ObjectivesMgr.h"

static const float kContentBorderWidth = 6.0f;
static const float kContentBorderCornerRadius = 8.0f;
static const float kBorderWidth = 6.0f;
static const float kOkCircleBorderWidth = 6.0f;
static const float kBorderCornerRadius = 8.0f;

@interface BasicObjectiveUI ()
{
    __weak GameObjective* _gameObjective;
}
- (void) setupContent;
- (void) didPressOk:(id)sender;
@end

@implementation BasicObjectiveUI

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    NSAssert(false, @"must call initWithGameObjective: to create this screen");
    return nil;
}

- (id) initWithGameObjective:(GameObjective *)gameObjective
{
    self = [super initWithNibName:@"BasicObjectiveUI" bundle:nil];
    if(self)
    {
        _gameObjective = gameObjective;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // setup layout
    [PogUIUtility setBorderOnView:self.contentView
                            width:kBorderWidth
                            color:[GameColors borderColorPostsWithAlpha:1.0f]
                     cornerRadius:kBorderCornerRadius];
    [self.contentView setBackgroundColor:[GameColors bubbleColorScanWithAlpha:1.0f]];
    [self.okCircle setBorderColor:[GameColors borderColorPostsWithAlpha:1.0f]];
    [self.okCircle setBorderWidth:kOkCircleBorderWidth];
    [self.okCircle setButtonTarget:self action:@selector(didPressOk:)];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setupContent];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setDescLabel:nil];
    [self setContentView:nil];
    [self setOkCircle:nil];
    [super viewDidUnload];
}

#pragma mark - internals
- (void) setupContent
{
    [self.descLabel setText:@"Hello Trader. This is a long long long long sentence with lots and lots of text"];
    [self.descLabel sizeToFit];
}

#pragma mark - button actions
- (void) didPressOk:(id)sender
{
    [[ObjectivesMgr getInstance] setCompletedForObjective:_gameObjective];
    [UIView animateWithDuration:0.2f
                     animations:^(void){
                         self.view.alpha = 0.0f;
                     }
                     completion:^(BOOL finished){
                         [self.navigationController popViewControllerAnimated:NO];
                     }];
}

@end
