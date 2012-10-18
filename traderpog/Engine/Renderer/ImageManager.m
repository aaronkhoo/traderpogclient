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
static NSString* const kImageReservedWordDefault = @"default";

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
- (UIImage*) getImage:(NSString *)name
{
    UIImage* result = [self getImage:name fallbackNamed:name];
    return result;
}

- (UIImage*) getImage:(NSString *)name fallbackNamed:(NSString *)fallback
{
    UIImage* result = nil;

    // check resource bundle only if name is not the reserved word "default"
    if([name compare:kImageReservedWordDefault] != NSOrderedSame)
    {
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
        if(result)
        {
            [self.imageCache setObject:result forKey:imageKey];
        }
    }
    
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

// http://stackoverflow.com/questions/1298867/convert-image-to-grayscale
- (UIImage *) getGrayscaleImage:(NSString*)name fallbackNamed:(NSString*)fallback
{
    // load the image
    UIImage *img = [self getImage:name fallbackNamed:fallback];

    const int RED = 1;
    const int GREEN = 2;
    const int BLUE = 3;
    
    // Create image rectangle with current image width/height
    CGRect imageRect = CGRectMake(0, 0, img.size.width * img.scale, img.size.height * img.scale);
    
    int width = imageRect.size.width;
    int height = imageRect.size.height;
    
    // the pixels will be painted to this array
    uint32_t *pixels = (uint32_t *) malloc(width * height * sizeof(uint32_t));
    
    // clear the pixels so any transparency is preserved
    memset(pixels, 0, width * height * sizeof(uint32_t));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // create a context with RGBA pixels
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, 8, width * sizeof(uint32_t), colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast);
    
    // paint the bitmap to our context which will fill in the pixels array
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), [img CGImage]);
    
    for(int y = 0; y < height; y++) {
        for(int x = 0; x < width; x++) {
            uint8_t *rgbaPixel = (uint8_t *) &pixels[y * width + x];
            
            // convert to grayscale using recommended method: http://en.wikipedia.org/wiki/Grayscale#Converting_color_to_grayscale
            uint32_t gray = 0.3 * rgbaPixel[RED] + 0.59 * rgbaPixel[GREEN] + 0.11 * rgbaPixel[BLUE];
            
            // set the pixels to gray
            rgbaPixel[RED] = gray;
            rgbaPixel[GREEN] = gray;
            rgbaPixel[BLUE] = gray;
        }
    }
    
    // create a new CGImageRef from our context with the modified pixels
    CGImageRef image = CGBitmapContextCreateImage(context);
    
    // we're done with the context, color space, and pixels
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    free(pixels);
    
    // make a new UIImage to return
    UIImage *resultUIImage = [UIImage imageWithCGImage:image
                                                 scale:img.scale
                                           orientation:UIImageOrientationUp];
    
    // we're done with image now too
    CGImageRelease(image);
    
    return resultUIImage;
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
