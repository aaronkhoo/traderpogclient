//
//  PogUIUtility.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 2/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "PogUIUtility.h"
#import <QuartzCore/QuartzCore.h>

@implementation PogUIUtility

#pragma mark - utility functions

static const float kSecondsPerHour = 3600.0;
static const float kSecondsPerMinute = 60.0;
+ (NSString*) stringFromTimeInterval:(NSTimeInterval)timeInterval
{
    NSString* result = nil;    
    NSTimeInterval hoursValue = floor(timeInterval / kSecondsPerHour);
    NSTimeInterval minutesValue = floor((timeInterval - (hoursValue * kSecondsPerHour)) / kSecondsPerMinute);
    NSTimeInterval secondsValue = floor(timeInterval - (hoursValue * kSecondsPerHour) - (minutesValue * kSecondsPerMinute));
    
    unsigned int hoursInt = (unsigned int)(hoursValue);
    unsigned int minutesInt = (unsigned int)(minutesValue);
    unsigned int secondsInt = (unsigned int)(secondsValue);
    
    NSString* minutesString = [NSString stringWithFormat:@"%d", minutesInt];
    if(10 > minutesInt)
    {
        minutesString = [NSString stringWithFormat:@"0%d", minutesInt];
    }
    NSString* secondsString = [NSString stringWithFormat:@"%d", secondsInt];
    if(10 > secondsInt)
    {
        secondsString = [NSString stringWithFormat:@"0%d", secondsInt];
    }
    if(0 < hoursInt)
    {
        result = [NSString stringWithFormat:@"%d:%@:%@", hoursInt, minutesString, secondsString];
    }
    else
    {
        result = [NSString stringWithFormat:@"%@:%@", minutesString, secondsString];        
    }
    return result;
}

+ (NSDate*) convertUtcToNSDate:(NSString*)utcdate
{
    // Set up conversion of RFC 3339 time format
    NSDateFormatter *rfc3339DateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    
    [rfc3339DateFormatter setLocale:enUSPOSIXLocale];
    [rfc3339DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    [rfc3339DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    // Convert the RFC 3339 date time string to an NSDate.
    return [rfc3339DateFormatter dateFromString:utcdate];
}

+ (NSString*) convertNSDateToUtc:(NSDate*)utcdate
{
    // Set up conversion of RFC 3339 time format
    NSDateFormatter *rfc3339DateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    
    [rfc3339DateFormatter setLocale:enUSPOSIXLocale];
    [rfc3339DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    [rfc3339DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    // Convert the RFC 3339 date time string to an NSDate.
    return [rfc3339DateFormatter stringFromDate:utcdate];
}

+ (NSString*)base64forData:(NSData*)theData
{
    const uint8_t* input = (const uint8_t*)[theData bytes];
    NSInteger length = [theData length];
    
    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
    
    NSMutableData* data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t* output = (uint8_t*)data.mutableBytes;
    
    NSInteger i;
    for (i=0; i < length; i += 3) {
        NSInteger value = 0;
        NSInteger j;
        for (j = i; j < (i + 3); j++) {
            value <<= 8;
            
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        
        NSInteger theIndex = (i / 3) * 4;
        output[theIndex + 0] =                    table[(value >> 18) & 0x3F];
        output[theIndex + 1] =                    table[(value >> 12) & 0x3F];
        output[theIndex + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
        output[theIndex + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
}

+ (NSString*) commaSeparatedStringFromUnsignedInt:(unsigned int)number
{
    NSNumberFormatter *priceStyle = [[NSNumberFormatter alloc] init];
    
    // set options.
    [priceStyle setFormatterBehavior:[NSNumberFormatter defaultFormatterBehavior]];
    [priceStyle setNumberStyle:NSNumberFormatterCurrencyStyle];
    [priceStyle setMaximumFractionDigits:0];
    [priceStyle setCurrencySymbol:@""];
    
    // get formatted string
    NSString* formatted = [priceStyle stringFromNumber:[NSNumber numberWithUnsignedInt:number]]; 
    return formatted;
}

+ (NSString*) currencyStringForAmount:(unsigned int)amount
{
    NSNumberFormatter *priceStyle = [[NSNumberFormatter alloc] init];
    
    // set options.
    [priceStyle setFormatterBehavior:[NSNumberFormatter defaultFormatterBehavior]];
    [priceStyle setNumberStyle:NSNumberFormatterCurrencyStyle];
    [priceStyle setMaximumFractionDigits:0];
    [priceStyle setCurrencySymbol:@""];
    
    // get formatted string
    NSString* formatted = [priceStyle stringFromNumber:[NSNumber numberWithUnsignedInt:amount]]; 
    return formatted;
}

+ (NSString*) stringTrimAllWhitespaces:(NSString*)src
{
    NSString* result = [src stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    return result;
}

+ (NSDate*) getMondayOfTheWeek
{
    NSDate *today = [[NSDate alloc] init];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    // Get the weekday component of the current date
    NSDateComponents *weekdayComponents = [gregorian components:NSWeekdayCalendarUnit fromDate:today];
    
    /*
     Create a date components to represent the number of days to subtract from the current date.
     The weekday value for Monday in the Gregorian calendar is 2. 
     */
    NSDateComponents *componentsToSubtract = [[NSDateComponents alloc] init];
    [componentsToSubtract setDay: 0 - (([weekdayComponents weekday] + 5) % 7)];
    
    NSDate *beginningOfWeek = [gregorian dateByAddingComponents:componentsToSubtract toDate:today options:0];
    
    /*
     beginningOfWeek now has the same hour, minute, and second as the original date (today).
     To normalize to midnight, extract the year, month, and day components and create a new date from those components.
     */
    NSDateComponents *components =
    [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit)
                 fromDate: beginningOfWeek];
    beginningOfWeek = [gregorian dateFromComponents:components];
    return beginningOfWeek;
}

+ (void) followUsOnTwitter
{
    // open the twitter app first, if twitter app not found, open it in safari
    NSString *peterpogTwitterLink = @"twitter://user?screen_name=geolopigs";  
    BOOL twitterAppOpened = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:peterpogTwitterLink]];  
    if(!twitterAppOpened)
    {
        NSString* peterpogTwitterHttpLink = @"http://twitter.com/#!/geolopigs";
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:peterpogTwitterHttpLink]];
    }    
}

+ (UIView*) createBorderForView:(UIView *)targetView
{
    CGRect borderRect = [targetView frame];
    UIView* borderView = [[UIView alloc] initWithFrame:borderRect];
    
    // init round corners
    [[borderView layer] setCornerRadius:4.0f];
    [[borderView layer] setMasksToBounds:YES];
    [[borderView layer] setBorderWidth:4.0f];
    [[borderView layer] setBorderColor:[[UIColor whiteColor] CGColor]];
    [borderView setBackgroundColor:[UIColor clearColor]];
    
    return borderView;
}

+ (UIView*) createScrimForView:(UIView *)targetView color:(UIColor *)color
{
    CGRect scrimRect = CGRectInset([targetView frame], 2, 2);
    UIView* scrimView = [[UIView alloc] initWithFrame:scrimRect];
    
    // init round corners
    [[scrimView layer] setCornerRadius:3.0f];
    [[scrimView layer] setMasksToBounds:YES];
    [[scrimView layer] setBorderWidth:1.0f];
    [[scrimView layer] setBorderColor:[[UIColor grayColor] CGColor]];
    [scrimView setBackgroundColor:color];
    
    return scrimView;    
}

+ (void) createScrimAndBorderForView:(UIView*)contentView
{
    UIView* borderView = [PogUIUtility createBorderForView:contentView];
    UIView* scrimView = [PogUIUtility createScrimForView:contentView 
                                                   color:[UIColor colorWithRed:0.1f green:0.158f blue:0.158f alpha:0.8f]];
    UIView* parentView = [contentView superview];
    [parentView insertSubview:borderView belowSubview:contentView];
    [parentView insertSubview:scrimView belowSubview:contentView];
}

+ (void) createInsertScrimForView:(UIView*)contentView
{
    UIView* scrimView = [PogUIUtility createScrimForView:contentView 
                                                   color:[UIColor colorWithRed:0.1f green:0.158f blue:0.158f alpha:0.8f]];
    UIView* parentView = [contentView superview];
    [parentView insertSubview:scrimView belowSubview:contentView];
}

+ (void) setRoundCornersForView:(UIView *)targetView
{
    // init round corners
    [[targetView layer] setCornerRadius:8.0f];
    [[targetView layer] setMasksToBounds:YES];
}

+ (void) setRoundCornersForView:(UIView *)targetView withCornerRadius:(float)radius
{
    // init round corners
    [[targetView layer] setCornerRadius:radius];
    [[targetView layer] setMasksToBounds:YES];
}

+ (void) setCircleForView:(UIView *)targetView
{
    // init round corners
    float width = targetView.bounds.size.width;
    [[targetView layer] setCornerRadius:0.5f * width];
    [[targetView layer] setMasksToBounds:YES];
    [[targetView layer] setBorderWidth:4.0f];
    [[targetView layer] setBorderColor:[[UIColor clearColor] CGColor]];
}

+ (void) setCircleForView:(UIView *)targetView withBorderWidth:(float)borderWidth borderColor:(UIColor*)borderColor
{
    [PogUIUtility setCircleForView:targetView withBorderWidth:borderWidth borderColor:borderColor rasterizeScale:1.0f];
}

+ (void) setCircleForView:(UIView *)targetView
          withBorderWidth:(float)borderWidth
              borderColor:(UIColor*)borderColor
           rasterizeScale:(float)rasterScale
{
    float width = targetView.bounds.size.width;
    [[targetView layer] setCornerRadius:0.5f * width];
    [[targetView layer] setMasksToBounds:YES];
    [[targetView layer] setBorderWidth:borderWidth];
    [[targetView layer] setBorderColor:[borderColor CGColor]];
    [[targetView layer] setRasterizationScale:[[UIScreen mainScreen] scale] * rasterScale];
    [[targetView layer] setShouldRasterize:YES];
}

+ (void) setBorderOnView:(UIView*)view width:(float)borderWidth color:(UIColor*)borderColor
{
    [[view layer] setBorderWidth:borderWidth];
    [[view layer] setBorderColor:[borderColor CGColor]];
}

+ (void) setBorderOnView:(UIView*)view width:(float)borderWidth color:(UIColor*)borderColor cornerRadius:(float)cornerRadius
{
    [[view layer] setBorderWidth:borderWidth];
    [[view layer] setBorderColor:[borderColor CGColor]];
    [[view layer] setCornerRadius:cornerRadius];
}

+ (void) setCircleShadowOnView:(UIView *)view shadowColor:(UIColor *)shadowColor
{
    CGRect circleFrame = [view bounds];
    CAShapeLayer* shadowLayer = [CAShapeLayer layer];
    [shadowLayer setFrame:circleFrame];
    
    // Standard shadow stuff
    [shadowLayer setShadowColor:shadowColor.CGColor];
    [shadowLayer setShadowOffset:CGSizeMake(0.0f, 0.0f)];
    [shadowLayer setShadowOpacity:1.0f];
    [shadowLayer setShadowRadius:4];
    
    // Causes the inner region in this example to NOT be filled.
    [shadowLayer setFillRule:kCAFillRuleEvenOdd];
    
    // Create the larger rectangle path.
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, CGRectInset(circleFrame, -4, -4));
    
    // Add the inner path so it's subtracted from the outer path.
    // someInnerPath could be a simple bounds rect, or maybe
    // a rounded one for some extra fanciness.
    CGPoint circleCenter = CGPointMake(circleFrame.origin.x + (circleFrame.size.width * 0.5f),
                                       circleFrame.origin.y + (circleFrame.size.height * 0.5f));
    UIBezierPath* circlePath = [UIBezierPath bezierPathWithArcCenter:circleCenter
                                                              radius:circleFrame.size.width * 0.48f
                                                          startAngle:0.0f
                                                            endAngle:2.0f * M_PI
                                                           clockwise:YES];
    CGPathAddPath(path, NULL, circlePath.CGPath);
    CGPathCloseSubpath(path);
    
    [shadowLayer setPath:path];
    CGPathRelease(path);
    
    [[view layer] addSublayer:shadowLayer];
}

static const float kFadeAlertWidth = 240.0;
static const float kFadeAlertHeight = 40.0f;

+ (UIView*) createFadeAlert:(NSString *)message
{
    UIView* containerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kFadeAlertWidth, kFadeAlertHeight)];
    UILabel* messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kFadeAlertWidth, kFadeAlertHeight)];
    [messageLabel setText:message];
    [messageLabel setFont:[UIFont fontWithName:@"Helvetica" size:12.0f]];
    [messageLabel setTextAlignment:UITextAlignmentCenter];
    [messageLabel setAdjustsFontSizeToFitWidth:YES];

    [containerView addSubview:messageLabel];
    
    return containerView;
}

+ (void) fadeView:(UIView*)parentView toColor:(UIColor*)color completion:(CompletionBlock)completionBlock
{
    UIView* colorView = [[UIView alloc] initWithFrame:[parentView bounds]];
    [colorView setBackgroundColor:color];
    [parentView addSubview:colorView];
    
    [colorView setAlpha:0.0f];
    [UIView animateWithDuration:0.5f
                          delay:0.0f 
                        options:UIViewAnimationCurveEaseIn 
                     animations:^{
                         [colorView setAlpha:1.0f];
                     }
                     completion:^(BOOL finished){
                         [colorView removeFromSuperview];
                         if(completionBlock)
                         {
                             completionBlock(finished);
                         }
                     }];
}

+ (void) fadeView:(UIView*)parentView fromColor:(UIColor*)color completion:(CompletionBlock)completionBlock
{
    UIView* colorView = [[UIView alloc] initWithFrame:[parentView bounds]];
    [colorView setBackgroundColor:color];
    [parentView addSubview:colorView];
    
    [colorView setAlpha:1.0f];
    [UIView animateWithDuration:0.5f
                          delay:0.0f 
                        options:UIViewAnimationCurveEaseIn 
                     animations:^{
                         [colorView setAlpha:0.0f];
                     }
                     completion:^(BOOL finished){
                         [colorView removeFromSuperview];
                         if(completionBlock)
                         {
                             completionBlock(finished);
                         }
                     }];
}

+ (unsigned int) smallerDiffFromMarker:(unsigned int)markA toMarker:(unsigned int)markB numMarkers:(unsigned int)num
{
    markA = MIN(markA, num - 1);
    markB = MIN(markB, num - 1);
    unsigned int diff = 0;
    if(markA > markB)
    {
        unsigned int regDiff = markA - markB;
        unsigned int altDiff = (num - markA) + markB;
        diff = MIN(regDiff, altDiff);
    }
    else if(markA < markB)
    {
        unsigned int regDiff = markB - markA;
        unsigned int altDiff = (num - markB) + markA;
        diff = MIN(regDiff, altDiff);
    }
    return diff;
}

+ (float) gaussianFor:(float)x withA:(float)a b:(float)b c:(float)c
{
    float power = ((x - b) * (x - b)) / (2.0f * c * c);
    float result = a * powf(M_E, -power);
    return result;
}

+ (NSString*) versionStringForCurConfig
{
#if DEBUG
    // if running from xcode, show "github" as version label
    return @"e4919f3";
#else
    // version string
    NSString *versionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey];
    return [NSString stringWithFormat:@"%@", versionString];
#endif
}

#pragma mark - ui frame calculations
+ (CGRect) createCenterFrameWithSize:(CGSize)size inFrame:(CGRect)targetFrame
{
    CGRect result = [PogUIUtility createCenterFrameWithSize:size inFrame:targetFrame withFrameSize:size];
    return result;
}

// create a frame with frameSize, centered in targetFrame using size as its centering size
+ (CGRect) createCenterFrameWithSize:(CGSize)size inFrame:(CGRect)targetFrame withFrameSize:(CGSize)frameSize
{
    float originX = targetFrame.origin.x + (0.5f * (targetFrame.size.width - size.width));
    float originY = targetFrame.origin.y + (0.5f * (targetFrame.size.height - size.height));
    return CGRectMake(originX, originY, frameSize.width, frameSize.height);
}

@end
