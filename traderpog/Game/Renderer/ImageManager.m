//
//  ImageManager.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/8/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "ImageManager.h"
#import "AppDelegate.h"

@interface ImageManager ()
{
    UIView* _frontMenuBgView;
}
@property (strong,nonatomic) UIView* frontMenuBgView;
@end

@implementation ImageManager
@synthesize frontMenuBgView = _frontMenuBgView;

- (id) init
{
    self = [super init];
    if(self)
    {
        _frontMenuBgView = nil;
    }
    return self;
}

#pragma mark - frontend menu
- (void) loadFrontMenuBackground
{
    if(![self frontMenuBgView])
    {
        AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        NSString* backgroundImageName = @"Default.png";
        if([[UIScreen mainScreen] scale] > 1.0f)
        {
            backgroundImageName = @"Default@2x.png";
        }
        UIImage* backgroundImage = [UIImage imageNamed:backgroundImageName];
        UIImageView* imageView = [[UIImageView alloc] initWithFrame:delegate.window.bounds];
        imageView.image = backgroundImage;
        [delegate.window addSubview:imageView];
        [delegate.window sendSubviewToBack:imageView];
        self.frontMenuBgView = imageView;
    }
}

- (void) unloadFrontMenuBackground
{
    if([self frontMenuBgView])
    {
        [self.frontMenuBgView removeFromSuperview];
        self.frontMenuBgView = nil;
    }
}


#pragma mark - Singleton
static ImageManager* singleton = nil;
+ (ImageManager*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
			singleton = [[ImageManager alloc] init];
		}
	}
	return singleton;
}

+ (void) destroyInstance
{
	@synchronized(self)
	{
		singleton = nil;
	}
}

@end
