//
//  NewHomeSelectItem.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/13/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "NewHomeSelectItem.h"
#import "ConfirmNewPost.h"
#import "UINavigationController+Pog.h"

@interface NewHomeSelectItem ()
{
    CLLocationCoordinate2D _coordinate;
    NSString* _itemId;
}
@end

@implementation NewHomeSelectItem
@synthesize imageLeft;
@synthesize imageMiddle;
@synthesize imageRight;
@synthesize labelLeft;
@synthesize labelMiddle;
@synthesize labelRight;

- (id) initWithCoordinate:(CLLocationCoordinate2D)coord item:(NSString*)itemId;
{
    self = [super initWithNibName:@"NewHomeSelectItem" bundle:nil];
    if (self) 
    {
        _coordinate = coord;
        _itemId = itemId;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [self setLabelLeft:nil];
    [self setLabelMiddle:nil];
    [self setLabelRight:nil];
    [self setImageLeft:nil];
    [self setImageMiddle:nil];
    [self setImageRight:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)didPressOkLeft:(id)sender 
{
    ConfirmNewPost* nextScreen = [[ConfirmNewPost alloc] initForHomebaseWithCoordinate:_coordinate
                                                                                  item:_itemId];
    [self.navigationController pushFadeInViewController:nextScreen animated:YES];
}

- (IBAction)didPressOkMiddle:(id)sender 
{
}

- (IBAction)didPressOkRight:(id)sender 
{
}
@end
