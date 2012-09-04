//
//  FlightPathView.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 5/16/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "FlightPathView.h"
#import "FlightPathOverlay.h"

static NSString* const keySrcCoord = @"srcCoord";
static NSString* const keyDestCoord = @"destCoord";
static NSString* const keyCurCoord = @"curCoord";

@implementation FlightPathView
@synthesize mapView = _mapView;

- (FlightPathOverlay*) flightPathOverlay
{
    return (FlightPathOverlay*) self.overlay;
}

- (id)initWithOverlay:(id <MKOverlay>)overlay 
{
	NSAssert(0, @"-initWithFlightPathOverlay: is the designated initializer");
	return nil;
}

- (id) initWithFlightPathOverlay:(FlightPathOverlay *)flightPathOverlay
{
    self = [super initWithOverlay:flightPathOverlay];
    if(self)
    {
        [self.flightPathOverlay addObserver:self forKeyPath:keySrcCoord options:0 context:nil];
        [self.flightPathOverlay addObserver:self forKeyPath:keyDestCoord options:0 context:nil];
        [self.flightPathOverlay addObserver:self forKeyPath:keyCurCoord options:0 context:nil];
        _mapView = nil;
    }
    return self;
}

- (void) dealloc
{
    // no need to release _mapView because it's not retained;

    [self.flightPathOverlay removeObserver:self forKeyPath:keySrcCoord];
    [self.flightPathOverlay removeObserver:self forKeyPath:keyDestCoord];
    [self.flightPathOverlay removeObserver:self forKeyPath:keyCurCoord];
}

#pragma mark - MKOverlayPathView

static BOOL lineIntersectsRect(MKMapPoint p0, MKMapPoint p1, MKMapRect r) {
    double minX = MIN(p0.x, p1.x);
    double minY = MIN(p0.y, p1.y);
    double maxX = MAX(p0.x, p1.x);
    double maxY = MAX(p0.y, p1.y);
    
    MKMapRect r2 = MKMapRectMake(minX, minY, maxX - minX, maxY - minY);
    return MKMapRectIntersectsRect(r, r2);
}

#define MIN_POINT_DELTA 5.0

- (CGPathRef)createPathForPoints:(MKMapPoint *)points
                      pointCount:(NSUInteger)pointCount
                        clipRect:(MKMapRect)mapRect
                       zoomScale:(MKZoomScale)zoomScale
{
    // The fastest way to draw a path in an MKOverlayView is to simplify the
    // geometry for the screen by eliding points that are too close together
    // and to omit any line segments that do not intersect the clipping rect.  
    // While it is possible to just add all the points and let CoreGraphics 
    // handle clipping and flatness, it is much faster to do it yourself:
    
    if (pointCount < 2)
        return NULL;
    
    CGMutablePathRef path = NULL;
    
    BOOL needsMove = YES;
    
#define POW2(a) ((a) * (a))
    
    // Calculate the minimum distance between any two points by figuring out
    // how many map points correspond to MIN_POINT_DELTA of screen points
    // at the current zoomScale.
    double minPointDelta = MIN_POINT_DELTA / zoomScale;
    double c2 = POW2(minPointDelta);
    
    MKMapPoint point, lastPoint = points[0];
    NSUInteger i;
    for (i = 1; i < pointCount - 1; i++) {
        point = points[i];
        double a2b2 = POW2(point.x - lastPoint.x) + POW2(point.y - lastPoint.y);
        if (a2b2 >= c2) {
            if (lineIntersectsRect(point, lastPoint, mapRect)) {
                if (!path) 
                    path = CGPathCreateMutable();
                if (needsMove) {
                    CGPoint lastCGPoint = [self pointForMapPoint:lastPoint];
                    CGPathMoveToPoint(path, NULL, lastCGPoint.x, lastCGPoint.y);
                }
                CGPoint cgPoint = [self pointForMapPoint:point];
                CGPathAddLineToPoint(path, NULL, cgPoint.x, cgPoint.y);
            } else {
                // discontinuity, lift the pen
                needsMove = YES;
            }
            lastPoint = point;
        }
    }
    
#undef POW2
    
    // If the last line segment intersects the mapRect at all, add it unconditionally
    point = points[pointCount - 1];
    if (lineIntersectsRect(lastPoint, point, mapRect)) {
        if (!path)
            path = CGPathCreateMutable();
        if (needsMove) {
            CGPoint lastCGPoint = [self pointForMapPoint:lastPoint];
            CGPathMoveToPoint(path, NULL, lastCGPoint.x, lastCGPoint.y);
        }
        CGPoint cgPoint = [self pointForMapPoint:point];
        CGPathAddLineToPoint(path, NULL, cgPoint.x, cgPoint.y);
    }
    
    return path;
}


- (void)drawMapRect:(MKMapRect)mapRect
          zoomScale:(MKZoomScale)zoomScale
          inContext:(CGContextRef)context
{
    // create path
    FlightPathOverlay* flightPath = (FlightPathOverlay*)(self.overlay);
    CGFloat lineWidth = [[UIScreen mainScreen] scale] * 8.0f / zoomScale;
//    CGFloat lineWidth = MKRoadWidthAtZoomScale(zoomScale);
    MKMapRect clipRect = MKMapRectInset(mapRect, -lineWidth, -lineWidth);
    
    //[flightPath lockForReading];
    MKMapPoint srcPoint = MKMapPointForCoordinate(flightPath.srcCoord);
    MKMapPoint destPoint = MKMapPointForCoordinate(flightPath.destCoord);
    MKMapPoint curPoint = MKMapPointForCoordinate(flightPath.curCoord);
    //[flightPath unlockForReading];
    if(lineIntersectsRect(srcPoint, destPoint, clipRect))
    {
        CGMutablePathRef drawPath = CGPathCreateMutable();
        CGPoint srcDrawPoint = [self pointForMapPoint:srcPoint];
        CGPoint destDrawPoint = [self pointForMapPoint:destPoint];
        
        CGPathMoveToPoint(drawPath, NULL, srcDrawPoint.x, srcDrawPoint.y);
        CGPathAddLineToPoint(drawPath, NULL, destDrawPoint.x, destDrawPoint.y);

        CGMutablePathRef solidPath = CGPathCreateMutable();
        CGPoint curDrawPoint = [self pointForMapPoint:curPoint];
        CGPathMoveToPoint(solidPath, NULL, srcDrawPoint.x, srcDrawPoint.y);
        CGPathAddLineToPoint(solidPath, NULL, curDrawPoint.x, curDrawPoint.y);
        
        CGContextSaveGState(context);
        CGContextAddPath(context, drawPath);
        CGFloat dashLengths[2] = {lineWidth / 4.0f, 6.0f * lineWidth / 4.0f};
        CGContextSetLineDash(context, 0, dashLengths, 2);
        CGContextSetRGBStrokeColor(context, 237.0f/255.0f, 28.0f/255.0f, 36.0f/255.0f, 0.4);
        CGContextSetLineJoin(context, kCGLineJoinRound);
        CGContextSetLineCap(context, kCGLineCapSquare);
        CGContextSetLineWidth(context, lineWidth * 0.9f);
        
        
        CGContextStrokePath(context);
        CGPathRelease(drawPath);
        CGContextRestoreGState(context);

        CGContextSaveGState(context);
        CGContextAddPath(context, solidPath);
        CGContextSetRGBStrokeColor(context, 237.0f/255.0f, 28.0f/255.0f, 36.0f/255.0f, 1.0);
        CGContextSetLineJoin(context, kCGLineJoinMiter);
        CGContextSetLineCap(context, kCGLineCapRound);
        CGContextSetLineWidth(context, lineWidth);
        CGContextStrokePath(context);
        CGPathRelease(solidPath);
        CGContextRestoreGState(context);
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context 
{
    if([keyPath isEqualToString:keySrcCoord] || [keyPath isEqualToString:keyDestCoord])
    {
        [self setNeedsDisplayInMapRect:self.flightPathOverlay.boundingMapRect];
    }
    else if([keyPath isEqualToString:keyCurCoord])
    {
        // update only the bounding rect around curCoord
        MKMapRect updateRect = [self.flightPathOverlay curUpdateRect];
        MKMapRect intersectRect = MKMapRectIntersection(updateRect, [self.mapView visibleMapRect]);
        if(!MKMapRectIsEmpty(intersectRect))
        {
            [self setNeedsDisplayInMapRect:intersectRect];
        }
    }
}


@end
