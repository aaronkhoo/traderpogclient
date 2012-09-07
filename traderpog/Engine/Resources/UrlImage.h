//
//  UrlImage.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 9/6/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UrlImage : NSObject<NSURLConnectionDelegate>
{
    UIImageView* _imageView;
    UIImage* _image;
    NSURLConnection* _connection;
    NSMutableData* _dataBuffer;
}
@property (nonatomic,readonly) UIImage* image;
- (id) initWithUrl:(NSString*)urlString forImageView:(UIImageView*)imageView;
@end
