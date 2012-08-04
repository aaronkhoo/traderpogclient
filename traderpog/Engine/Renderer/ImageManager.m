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
    NSMutableDictionary* _imageCache;
}
@property (strong,nonatomic) UIView* frontMenuBgView;
@property (nonatomic,strong) NSMutableDictionary* imageCache;
@end

@implementation ImageManager
@synthesize frontMenuBgView = _frontMenuBgView;
@synthesize imageCache = _imageCache;
- (id) init
{
    self = [super init];
    if(self)
    {
        _frontMenuBgView = nil;
        _imageCache = [NSMutableDictionary dictionaryWithCapacity:10];
    }
    return self;
}

#pragma mark - image accessors
- (UIImage*) getImageWithUrl:(NSString *)url fallbackNamed:(NSString *)fallback
{
    UIImage* result = nil;

    // check cache first
    NSString* imageKey = url;
    if(!imageKey)
    {
        imageKey = fallback;
    }
    result = [self.imageCache objectForKey:imageKey];

    // HACK
    // TODO: load from URL
    if(!result && url)
    {
        
    }
    // HACK
    
    // check main bundle
    if(!result)
    {
        result = [UIImage imageNamed:fallback];
    }
    
    return result;
}

#pragma mark - frontend menu
- (void) loadFrontMenuBackgroundNamed:(NSString *)imageName
{
    if(![self frontMenuBgView])
    {
        AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        NSString* backgroundImageName = imageName;
        if([[UIScreen mainScreen] scale] > 1.0f)
        {
            backgroundImageName = [NSString stringWithFormat:@"%@@2x.%@", 
                                   [imageName stringByDeletingPathExtension],
                                   [imageName pathExtension]];
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
