//
//  ImageManager.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/8/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "ImageManager.h"
#import "AppDelegate.h"
#import "ResourceManager.h"

static NSString* const kImageSubGame = @"game";
static NSString* const kImageSubShared = @"shared";
static NSString* const kImageSubUi = @"ui";

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
- (UIImage*) getImage:(NSString *)name fallbackNamed:(NSString *)fallback
{
    UIImage* result = nil;

    // check cache first
    NSString* imageKey = name;
    if(!imageKey)
    {
        imageKey = fallback;
    }
    result = [self.imageCache objectForKey:imageKey];

    // Check downloaded resource package
    if(!result && name)
    {
        NSString* const imageSubs[] =
        {
            kImageSubGame,
            kImageSubShared,
            kImageSubUi,
            nil
        };
        NSString* path = nil;
        unsigned int subIndex = 0;
        while(imageSubs[subIndex])
        {
            path = [[ResourceManager getInstance] getImagePath:imageSubs[subIndex] forResource:name];
            if(path)
            {
                break;
            }
            ++subIndex;
        }

        if (path)
        {
            result = [[UIImage alloc] initWithContentsOfFile:path];
        }
    }
    
    // check main bundle
    if(!result)
    {
        result = [UIImage imageNamed:fallback];
    }
    
    if(result)
    {
        [self.imageCache setObject:result forKey:imageKey];
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

// reference: http://coffeeshopped.com/2010/09/iphone-how-to-dynamically-color-a-uiimage
- (UIImage*) getImage:(NSString *)name fallbackNamed:(NSString *)fallback withColor:(UIColor *)color
{
    // load the image
    UIImage *img = [self getImage:name fallbackNamed:fallback];
    
    // begin a new image context, to draw our colored image onto
    UIGraphicsBeginImageContext(img.size);
    
    // get a reference to that context we created
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // set the fill color
    [color setFill];
    
    // translate/flip the graphics context (for transforming from CG* coords to UI* coords
    CGContextTranslateCTM(context, 0, img.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    // set the blend mode to color burn, and the original image
    CGContextSetBlendMode(context, kCGBlendModeColor);
    CGRect rect = CGRectMake(0, 0, img.size.width, img.size.height);
    CGContextDrawImage(context, rect, img.CGImage);
    
    // set a mask that matches the shape of the image, then draw (color burn) a colored rectangle
    CGContextClipToMask(context, rect, img.CGImage);
    CGContextAddRect(context, rect);
    CGContextDrawPath(context,kCGPathFill);
    
    // generate a new UIImage from the graphics context we drew onto
    UIImage *coloredImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //return the color-burned image
    return coloredImg;
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
