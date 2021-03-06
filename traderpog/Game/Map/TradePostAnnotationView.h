//
//  TradePostAnnotationView.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 7/15/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MapProtocols.h"

extern NSString* const kTradePostAnnotationViewReuseId;
extern NSString* const kKeyFlyerAtPost;

@class TradePostAnnotation;
@class Flyer;
@class ItemBubble;
@interface TradePostAnnotationView : MKAnnotationView<MapAnnotationViewProtocol>
{
    UIImageView* _imageView;
    UIImageView* _frontImageView;
    UIImageView* _frontLeftView;
    UIImageView* _excImageView;
    ItemBubble*  _itemBubble;
    UIView*      _countdownView;
    UILabel*     _countdownLabel;
}
@property (nonatomic,strong) UIImageView* imageView;
@property (nonatomic,strong) UIImageView* frontImageView;
@property (nonatomic,strong) UIImageView* frontLeftView;
@property (nonatomic,strong) UIImageView* excImageView;
@property (nonatomic,strong) ItemBubble* itemBubble;
@property (nonatomic,strong) UIView* countdownView;
@property (nonatomic,strong) UILabel* countdownLabel;

- (id) initWithAnnotation:(NSObject<MKAnnotation>*)annotation;
@end
