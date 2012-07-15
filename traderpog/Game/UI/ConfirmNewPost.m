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
#import "GameManager.h"

@interface ConfirmNewPost ()
@property (nonatomic) CLLocationCoordinate2D postCoord;
@property (nonatomic) NSString* postItem;
@property (nonatomic) BOOL isHomebase;
@end

@implementation ConfirmNewPost
@synthesize postCoord;
@synthesize postItem;
@synthesize isHomebase;

- (id)initForTradePostWithCoordinate:(CLLocationCoordinate2D)coord item:(NSString *)itemId
{
    self = [super initWithNibName:@"ConfirmNewPost" bundle:nil];
    if (self) 
    {
        self.postCoord = coord;
        self.postItem = itemId;
        self.isHomebase = NO;
    }
    return self;
}

- (id)initForHomebaseWithCoordinate:(CLLocationCoordinate2D)coord item:(NSString *)itemId
{
    self = [super initWithNibName:@"ConfirmNewPost" bundle:nil];
    if (self) 
    {
        self.postCoord = coord;
        self.postItem = itemId;
        self.isHomebase = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
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
