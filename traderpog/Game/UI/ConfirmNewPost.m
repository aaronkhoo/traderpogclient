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
@end

@implementation ConfirmNewPost
@synthesize contentLabel;
@synthesize postCoord;
@synthesize postItem;

- (id)initForTradePostWithCoordinate:(CLLocationCoordinate2D)coord itemType:(TradeItemType *)itemType
{
    self = [super initWithNibName:@"ConfirmNewPost" bundle:nil];
    if (self) 
    {
        self.postCoord = coord;
        self.postItem = itemType;
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
    if ([[TradePostMgr getInstance] newTradePostAtCoord:self.postCoord 
                                            sellingItem:self.postItem])
    {
        [self.navigationController popToRootViewControllerAnimated:NO];
        [[GameManager getInstance] selectNextGameUI];
    }
    else 
    {
        // Something failed in the trade post creation, probably because another post
        // creation was already in flight. We should never get into this state. Log and 
        // move on so we can fix this during debug.
        NSLog(@"First trade post creation failed!");
    }
}
@end
