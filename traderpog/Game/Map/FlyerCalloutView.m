//
//  FlyerCalloutView.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/13/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "FlyerCalloutView.h"
#import "FlyerCallout.h"
#import "Flyer.h"
#import "GameManager.h"

NSString* const kFlyerCalloutViewReuseId = @"FlyerCalloutView";

@implementation FlyerCalloutView
- (id) initWithAnnotation:(id<MKAnnotation>)annotation
{
    self = [super initWithAnnotation:annotation reuseIdentifier:kFlyerCalloutViewReuseId];
    if(self)
    {
        [[NSBundle mainBundle] loadNibNamed:@"FlyerCalloutView" owner:self options:nil];
    }
    return self;
}


- (IBAction)didPressLab:(id)sender
{
    NSLog(@"Lab");
}

- (IBAction)didPressHome:(id)sender
{
    FlyerCallout* annot = (FlyerCallout*) [self annotation];
    [[GameManager getInstance] showHomeSelectForFlyer:[annot flyer]];
}
@end
