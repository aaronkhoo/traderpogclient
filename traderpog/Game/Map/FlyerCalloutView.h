//
//  FlyerCalloutView.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 8/13/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CalloutAnnotationView.h"

extern NSString* const kFlyerCalloutViewReuseId;
@interface FlyerCalloutView : CalloutAnnotationView
- (IBAction)didPressHome:(id)sender;
@end
