//
//  UrlImage.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 9/6/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UrlImage;
typedef void (^LoadCompletionBlock)(UrlImage* urlImage);

@interface UrlImage : NSObject<NSURLConnectionDelegate>
{
    UIImageView* _imageView;
    UIImage* _image;
    NSURLConnection* _connection;
    NSMutableData* _dataBuffer;
    LoadCompletionBlock _completionBlock;
}
@property (nonatomic,readonly) UIImage* image;
- (id) initWithUrl:(NSString*)urlString forImageView:(UIImageView*)imageView;
- (id) initWithUrl:(NSString *)urlString completion:(LoadCompletionBlock)completion;
@end
