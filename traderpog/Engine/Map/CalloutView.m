//  This is my solution to the SO question "MKAnnotationView - Lock custom annotation view to pin on location updates":
//  http://stackoverflow.com/questions/6392931/mkannotationview-lock-custom-annotation-view-to-pin-on-location-updates
//
//  CalloutAnnotationView based on the work at: 
//  http://blog.asolutions.com/2010/09/building-custom-map-annotation-callouts-part-1/
//  
//  The Example* classes represent things you will probably change in your own project to fit your needs.  Consider CalloutAnnotationView abstract - it must be subclassed (here it's subclass is ExampleCalloutView), and linked with a xib connecting the IBOutlet for contentView.  The callout should resize to fit whatever view you supply as contentView.  

#import "CalloutView.h"
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>

#define CalloutMapAnnotationViewBottomShadowBufferSize 6.0f
#define CalloutMapAnnotationViewContentHeightBuffer 8.0f
#define CalloutMapAnnotationViewHeightAboveParent 12.0f
#define CalloutMapAnnotationViewInset 4.0f

@interface CalloutView()
@property (nonatomic, readonly) CGFloat yShadowOffset;
@property (nonatomic) BOOL animateOnNextDrawRect;

- (void)prepareFrameSize;
- (void)prepareOffset;
- (CGFloat)relativeParentXPosition;
- (void)adjustMapRegionIfNeeded;

@end


@implementation CalloutView
@synthesize contentFrame = _contentFrame;
@synthesize originalFrame = _originalFrame;
@synthesize parentAnnotationView = _parentAnnotationView;
@synthesize mapView = _mapView;
@synthesize contentView = _contentView;
@synthesize animateOnNextDrawRect = _animateOnNextDrawRect;
@synthesize yShadowOffset = _yShadowOffset;

- (id)initWithAnnotation:(id<MKAnnotation>)annotation;
{
    [NSException raise:NSInternalInconsistencyException 
                format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
    return nil;
}

- (id) initWithAnnotation:(id <MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
	if ((self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier])) {
		self.enabled = NO;
		self.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = YES;
	}
	return self;
}

- (void)setAnnotation:(id <MKAnnotation>)annotation
{
	[super setAnnotation:annotation];
    if(annotation)
    {
        [self prepareFrameSize];
    }
	[self setNeedsDisplay];
}

- (void)setAnnotationAndAdjustMap:(id <MKAnnotation>)annotation {
	[super setAnnotation:annotation];
	[self prepareFrameSize];
	[self adjustMapRegionIfNeeded];
	[self setNeedsDisplay];
}

- (void)prepareFrameSize {
	CGRect frame = self.frame;
	frame.size = self.contentView.frame.size;
	self.frame = frame;
    _originalFrame = frame;
}

- (void)prepareOffset {
	CGFloat xOffset = 0;
	
	//Add half our height plus half of the height of the annotation we are tied to so that our bottom lines up to its top
	//Then take into account its offset and the extra space needed for our drop shadow
	CGFloat yOffset = -((self.frame.size.height / 2) + (self.parentAnnotationView.frame.size.height * 0.45f));
	self.centerOffset = CGPointMake(xOffset, yOffset);
}

//if the pin is too close to the edge of the map view we need to shift the map view so the callout will fit.
- (void)adjustMapRegionIfNeeded {
	//Longitude
	CGFloat xPixelShift = 0;
	if ([self relativeParentXPosition] < 38) {
		xPixelShift = 38 - [self relativeParentXPosition];
	} else if ([self relativeParentXPosition] > self.frame.size.width - 38) {
		xPixelShift = (self.frame.size.width - 38) - [self relativeParentXPosition];
	}
	
	
	//Latitude

    // set parent transfor to identity before computing map-origin
    // in its frame, then restore the transform;
    // this is necessary because offset calculation assumes
    // parent without any transform
    CGAffineTransform parentTransform = self.parentAnnotationView.transform;
    [self.parentAnnotationView setTransform:CGAffineTransformIdentity];
	CGPoint mapViewOriginRelativeToParent = [self.mapView convertPoint:self.mapView.frame.origin toView:self.parentAnnotationView];
    [self.parentAnnotationView setTransform:parentTransform];

	CGFloat yPixelShift = 0;
    //NSLog(@"mapViewOrigin (%f, %f), self frame (%f, %f)", mapViewOriginRelativeToParent.x,
    //      mapViewOriginRelativeToParent.y, self.frame.size.width, self.frame.size.height);
	CGFloat pixelsFromTopOfMapView = -(mapViewOriginRelativeToParent.y + (0.5f * self.frame.size.height));
	CGFloat pixelsFromBottomOfMapView = self.mapView.frame.size.height + mapViewOriginRelativeToParent.y - self.parentAnnotationView.frame.size.height;
    //NSLog(@"pixeslFromTop %f", pixelsFromTopOfMapView);
	if (pixelsFromTopOfMapView < 7) {
		yPixelShift = 7 - pixelsFromTopOfMapView;
	} else if (pixelsFromBottomOfMapView < 10) {
		yPixelShift = -(10 - pixelsFromBottomOfMapView);
	}
	
	//Calculate new center point, if needed
	if (xPixelShift || yPixelShift) {
        //NSLog(@"yPixelShift %f", yPixelShift);
		CGFloat pixelsPerDegreeLongitude = self.mapView.frame.size.width / self.mapView.region.span.longitudeDelta;
		CGFloat pixelsPerDegreeLatitude = self.mapView.frame.size.height / self.mapView.region.span.latitudeDelta;
		
		CLLocationDegrees longitudinalShift = -(xPixelShift / pixelsPerDegreeLongitude);
		CLLocationDegrees latitudinalShift = yPixelShift / pixelsPerDegreeLatitude;
		
		CLLocationCoordinate2D newCenterCoordinate = {self.mapView.region.center.latitude + latitudinalShift, 
			self.mapView.region.center.longitude + longitudinalShift};
		
		[self.mapView setCenterCoordinate:newCenterCoordinate animated:YES];
		
		//fix for now
		self.frame = CGRectMake(self.frame.origin.x - xPixelShift,
								self.frame.origin.y - yPixelShift,
								self.frame.size.width, 
								self.frame.size.height);
		//fix for later (after zoom or other action that resets the frame)
		self.centerOffset = CGPointMake(self.centerOffset.x - xPixelShift, self.centerOffset.y);
	}
}


- (void)animateIn {
	CGFloat scale = 0.001f;
	self.transform = CGAffineTransformMake(scale, 0.0f, 0.0f, scale, 0.0f, 0.0f);
	[UIView beginAnimations:@"animateIn" context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
	[UIView setAnimationDuration:0.12];
	[UIView setAnimationDidStopSelector:@selector(animateInStepTwo)];
	[UIView setAnimationDelegate:self];
	scale = 1.1;
	self.transform = CGAffineTransformMake(scale, 0.0f, 0.0f, scale, 0.0f, 0.0f);
    self.alpha = 1.0f;
	[UIView commitAnimations];
}

- (void)animateInStepTwo {
	[UIView beginAnimations:@"animateInStepTwo" context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.075];
	[UIView setAnimationDidStopSelector:@selector(animateInStepThree)];
	[UIView setAnimationDelegate:self];
	
	CGFloat scale = 0.95;
	self.transform = CGAffineTransformMake(scale, 0.0f, 0.0f, scale, 0.0f, 0.0f);
	
	[UIView commitAnimations];
}

- (void)animateInStepThree {
	[UIView beginAnimations:@"animateInStepThree" context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.05];
	
	CGFloat scale = 1.0;
	self.transform = CGAffineTransformMake(scale, 0.0f, 0.0f, scale, 0.0f, 0.0f);
	
	[UIView commitAnimations];
}

- (void) animateOut
{
    CGFloat scale = 1.0;
	self.transform = CGAffineTransformMake(scale, 0.0f, 0.0f, scale, 0.0f, 0.0f);
	[UIView beginAnimations:@"animateOutStepOne" context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.05];
	[UIView setAnimationDidStopSelector:@selector(animateOutStepTwo)];
	[UIView setAnimationDelegate:self];
	scale = 1.1;
	self.transform = CGAffineTransformMake(scale, 0.0f, 0.0f, scale, 0.0f, 0.0f);
	[UIView commitAnimations];
}

- (void) animateOutStepTwo
{
    [UIView beginAnimations:@"animateOutStepTwo" context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.12];
	[UIView setAnimationDidStopSelector:@selector(animateOutStepThree)];
	[UIView setAnimationDelegate:self];
	CGFloat scale = 0.001f;
	self.transform = CGAffineTransformMake(scale, 0.0f, 0.0f, scale, 0.0f, 0.0f);
    self.alpha = 0.0f;
	[UIView commitAnimations];
}

- (void) animateOutStepThree
{
    if([self mapView])
    {
        [self.mapView removeAnnotation:self.annotation];
    }
}

- (void)didMoveToSuperview {
	[self adjustMapRegionIfNeeded];
	[self animateIn];
}

/*
- (void)drawRect:(CGRect)rect {
	CGFloat stroke = 1.0;
	CGFloat radius = 7.0;
	CGMutablePathRef path = CGPathCreateMutable();
	UIColor *color;
	CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGFloat parentX = [self relativeParentXPosition];
	
	//Determine Size
	rect = self.bounds;
	rect.size.width -= stroke + 14;
	rect.size.height -= stroke + 14 + CalloutMapAnnotationViewHeightAboveParent;
	rect.origin.x += stroke / 2.0 + 7;
	rect.origin.y += stroke / 2.0 + 7;
    
	//Create Path For Callout Bubble
	CGPathMoveToPoint(path, NULL, rect.origin.x, rect.origin.y + radius);
	CGPathAddLineToPoint(path, NULL, rect.origin.x, rect.origin.y + rect.size.height - radius);
	CGPathAddArc(path, NULL, rect.origin.x + radius, rect.origin.y + rect.size.height - radius, radius, M_PI, M_PI / 2, 1);
	CGPathAddLineToPoint(path, NULL, parentX - 15, rect.origin.y + rect.size.height);
	CGPathAddLineToPoint(path, NULL, parentX, rect.origin.y + rect.size.height + 15);
	CGPathAddLineToPoint(path, NULL, parentX + 15, rect.origin.y + rect.size.height);
	CGPathAddLineToPoint(path, NULL, rect.origin.x + rect.size.width - radius, rect.origin.y + rect.size.height);
	CGPathAddArc(path, NULL, rect.origin.x + rect.size.width - radius, rect.origin.y + rect.size.height - radius, radius, M_PI / 2, 0.0f, 1);
	CGPathAddLineToPoint(path, NULL, rect.origin.x + rect.size.width, rect.origin.y + radius);
	CGPathAddArc(path, NULL, rect.origin.x + rect.size.width - radius, rect.origin.y + radius, radius, 0.0f, -M_PI / 2, 1);
	CGPathAddLineToPoint(path, NULL, rect.origin.x + radius, rect.origin.y);
	CGPathAddArc(path, NULL, rect.origin.x + radius, rect.origin.y + radius, radius, -M_PI / 2, M_PI, 1);
	CGPathCloseSubpath(path);
	
	//Fill Callout Bubble & Add Shadow
	color = [[UIColor blackColor] colorWithAlphaComponent:.6];
	[color setFill];
	CGContextAddPath(context, path);
	CGContextSaveGState(context);
	//CGContextSetShadowWithColor(context, CGSizeMake (0, self.yShadowOffset), 6, [UIColor colorWithWhite:0 alpha:.5].CGColor);
	CGContextFillPath(context);
	CGContextRestoreGState(context);
	
	//Stroke Callout Bubble
	color = [[UIColor darkGrayColor] colorWithAlphaComponent:.9];
	[color setStroke];
	CGContextSetLineWidth(context, stroke);
	CGContextSetLineCap(context, kCGLineCapSquare);
	CGContextAddPath(context, path);
	CGContextStrokePath(context);
	
    
	//Cleanup
	CGPathRelease(path);
	//CGPathRelease(glossPath);
	CGColorSpaceRelease(space);
	//CGGradientRelease(gradient);
	//CGGradientRelease(gradient2);
}
*/
- (CGFloat)yShadowOffset {
	if (!_yShadowOffset) {
		float osVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
		if (osVersion >= 3.2) {
			_yShadowOffset = 6;
		} else {
			_yShadowOffset = -6;
		}
		
	}
	return _yShadowOffset;
}

- (CGFloat)relativeParentXPosition {
	return self.bounds.size.width / 2;
}

#pragma mark - PogMapAnnotationViewProtocol
- (void)didSelectAnnotationViewInMap:(MKMapView *)mapView
{
    
}

- (void)didDeselectAnnotationViewInMap:(MKMapView *)mapView
{

}


- (void)setContentView:(UIView *)newContentView
{
    [_contentView removeFromSuperview];
    _contentView = newContentView;
    
    [self addSubview:newContentView];
}

@end