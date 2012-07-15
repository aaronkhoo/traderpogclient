//
//  ConfirmNewPost.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/14/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "ConfirmNewPost.h"
#import "TradePostMgr.h"
#import "TradePost.h"
#import "TradeItemType.h"
#import "GameManager.h"

@interface ConfirmNewPost ()
@property (nonatomic) CLLocationCoordinate2D postCoord;
@property (nonatomic,weak) TradeItemType* postItem;
@property (nonatomic) BOOL isHomebase;
@end

@implementation ConfirmNewPost
@synthesize contentLabel;
@synthesize postCoord;
@synthesize postItem;
@synthesize isHomebase;

- (id)initForTradePostWithCoordinate:(CLLocationCoordinate2D)coord itemType:(TradeItemType *)itemType
{
    self = [super initWithNibName:@"ConfirmNewPost" bundle:nil];
    if (self) 
    {
        self.postCoord = coord;
        self.postItem = itemType;
        self.isHomebase = NO;
    }
    return self;
}

- (id)initForHomebaseWithCoordinate:(CLLocationCoordinate2D)coord itemType:(TradeItemType *)itemType
{
    self = [super initWithNibName:@"ConfirmNewPost" bundle:nil];
    if (self) 
    {
        self.postCoord = coord;
        self.postItem = itemType;
        self.isHomebase = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // content
    NSString* contentString = [NSString stringWithFormat:@"%@ Post", [self.postItem name]];
    [self.contentLabel setText:contentString];
}

- (void)viewDidUnload
{
    [self setContentLabel:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)didPressOk:(id)sender 
{
    [[TradePostMgr getInstance] newTradePostAtCoord:self.postCoord 
                                        sellingItem:self.postItem
                                         isHomebase:self.isHomebase];
    [self.navigationController popToRootViewControllerAnimated:NO];
    [[GameManager getInstance] selectNextGameUI];
}
@end
