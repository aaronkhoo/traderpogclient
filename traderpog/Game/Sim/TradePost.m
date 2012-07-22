//
//  TradePost.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "TradePost.h"
#import "TradeItemType.h"
#import "TradePostAnnotation.h"

static NSString* const kKeyPostId = @"postId";
static NSString* const kKeyLong = @"longitude";
static NSString* const kKeyLat = @"latitude";
static NSString* const kKeyItem = @"item";
static NSString* const kKeyHomebaseBool = @"homebaseBool";

@implementation TradePost
@synthesize postId = _postId;
@synthesize itemId = _itemId;
@synthesize isHomebase = _isHomebase;
@synthesize annotation = _annotation;

- (id) initWithPostId:(NSString*)postId
           coordinate:(CLLocationCoordinate2D)coordinate 
                 itemType:(TradeItemType *)itemType
{
    self = [super init];
    if(self)
    {
        _postId = postId;
        _coord = coordinate;
        _itemId = [itemType itemId];
        _isHomebase = NO;
        _annotation = nil;
    }
    return self;
}

#pragma mark - getters/setters
- (CLLocationCoordinate2D) coord
{
    return _coord;
}

- (void) setCoord:(CLLocationCoordinate2D)coord
{
    _coord = coord;
    if([self annotation])
    {
        [self.annotation setCoordinate:coord];
    }
}

#pragma mark - NSCoding
- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.postId forKey:kKeyPostId];
    [aCoder encodeDouble:self.coord.latitude forKey:kKeyLat];
    [aCoder encodeDouble:self.coord.longitude forKey:kKeyLong];
    [aCoder encodeObject:self.itemId forKey:kKeyItem];
    [aCoder encodeBool:self.isHomebase forKey:kKeyHomebaseBool];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self.postId = [aDecoder decodeObjectForKey:kKeyPostId];
    self.coord = CLLocationCoordinate2DMake([aDecoder decodeDoubleForKey:kKeyLat], 
                                            [aDecoder decodeDoubleForKey:kKeyLong]);
    self.itemId = [aDecoder decodeObjectForKey:kKeyItem];
    self.isHomebase = [aDecoder decodeBoolForKey:kKeyHomebaseBool];
    
    // this will be set later when the Posts get added to the map on world restore
    self.annotation = nil;
    return self;
}

@end
