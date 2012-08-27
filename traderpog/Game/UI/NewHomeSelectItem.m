//
//  NewHomeSelectItem.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/13/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "NewHomeSelectItem.h"
#import "ConfirmNewPost.h"
#import "TradePostMgr.h"
#import "TradeItemType.h"
#import "TradeItemTypes.h"
#import "UINavigationController+Pog.h"


enum kItemSlots
{
    kItemSlotLeft = 0,
    kItemSlotMiddle,
    kItemSlotRight,
    
    kItemSlotNum
};

@interface NewHomeSelectItem ()
{
    CLLocationCoordinate2D _coordinate;
}
@property (nonatomic,strong) NSArray* itemUILabels;
- (void) selectItemChoiceAtIndex:(unsigned int)index;
@end

@implementation NewHomeSelectItem
@synthesize itemUILabels;
@synthesize imageLeft;
@synthesize imageMiddle;
@synthesize imageRight;
@synthesize labelLeft;
@synthesize labelMiddle;
@synthesize labelRight;

- (id) initWithCoordinate:(CLLocationCoordinate2D)coord;
{
    self = [super initWithNibName:@"NewHomeSelectItem" bundle:nil];
    if (self) 
    {
        _coordinate = coord;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // setup item choices
    self.itemUILabels = [NSArray arrayWithObjects:
                         [self labelLeft],
                         [self labelMiddle],
                         [self labelRight], nil];
    unsigned int count = 0;
    for(UILabel* cur in [self itemUILabels])
    {
        // TODO: itemTypes is no longer an array but a dictionary. Is NewHomeSelectItem still a valid class?
        //       Not being used anywhere
        //[cur setText:[[[[TradeItemTypes getInstance] itemTypes] objectAtIndex:count] name]];
        ++count;
    }
}

- (void)viewDidUnload
{
    [self setLabelLeft:nil];
    [self setLabelMiddle:nil];
    [self setLabelRight:nil];
    [self setImageLeft:nil];
    [self setImageMiddle:nil];
    [self setImageRight:nil];
    [self setItemUILabels:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)didPressOkLeft:(id)sender 
{
    [self selectItemChoiceAtIndex:kItemSlotLeft];
}

- (IBAction)didPressOkMiddle:(id)sender 
{
    [self selectItemChoiceAtIndex:kItemSlotMiddle];
}

- (IBAction)didPressOkRight:(id)sender 
{
    [self selectItemChoiceAtIndex:kItemSlotRight];
}

#pragma mark - internal methods
- (void) selectItemChoiceAtIndex:(unsigned int)index
{
    // TODO: itemTypes is no longer an array but a dictionary. Is NewHomeSelectItem still a valid class?
    //       Not being used anywhere
    //TradeItemType* itemType = [[[TradeItemTypes getInstance] itemTypes] objectAtIndex:index];
    //ConfirmNewPost* nextScreen = [[ConfirmNewPost alloc] initForTradePostWithCoordinate:_coordinate
    //                             itemType:itemType];
    //[self.navigationController pushFadeInViewController:nextScreen animated:YES];
}
@end
