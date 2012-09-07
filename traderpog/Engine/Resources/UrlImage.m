//
//  UrlImage.m
//  traderpog
//
//  Created by Shu Chiun Cheah on 9/6/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "UrlImage.h"

@implementation UrlImage
@synthesize image = _image;

- (id) initWithUrl:(NSString*)urlString forImageView:(UIImageView*)imageView;
{
    self = [super init];
    if(self)
    {
        _imageView = imageView;
        _dataBuffer = [[NSMutableData alloc] init];
        _image = nil;
        
        NSURL* url = [NSURL URLWithString:urlString];
        NSURLRequest* request = [NSURLRequest requestWithURL:url];
        _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    }
    return self;
}

#pragma mark - NSURLConnectionDelegate
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_dataBuffer appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    _image = [UIImage imageWithData:_dataBuffer];
    [_imageView setImage:_image];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"download of beacon picture failed");
}


@end
