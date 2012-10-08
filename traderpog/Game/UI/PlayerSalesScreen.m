//
//  PlayerSalesScreen.m
//  traderpog
//
//  Created by Aaron Khoo on 10/5/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "UINavigationController+Pog.h"
#import "Player.h"
#import "PlayerSales.h"
#import "PlayerSalesScreen.h"
#import "UrlImage.h"
#import "UrlImageManager.h"

static NSString* const kFbPictureUrl = @"https://graph.facebook.com/%@/picture";

@interface PlayerSalesScreen ()

@end

@implementation PlayerSalesScreen
@synthesize mainText;
@synthesize fbName1;
@synthesize fbName2;
@synthesize fbName3;
@synthesize fbName4;
@synthesize fbName5;
@synthesize fbImage1;
@synthesize fbImage2;
@synthesize fbImage3;
@synthesize fbImage4;
@synthesize fbImage5;
@synthesize okButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    NSArray* fbidArray = [[PlayerSales getInstance] fbidArray];
    if ([fbidArray count] > 0)
    {
        NSUInteger index = 0;
        for (NSString* fbid in fbidArray)
        {
            NSString* fbName = [[Player getInstance] getFacebookNameByFbid:fbid];
            NSString* pictureUrlString = [NSString stringWithFormat:kFbPictureUrl,fbid];
            UrlImage* urlImage =[[UrlImageManager getInstance] getCachedImage:fbid];;
            switch (index)
            {
                case 0:
                    fbName1.text = fbName;
                    if (urlImage)
                    {
                        [fbImage1 setImage:[urlImage image]];
                    }
                    else
                    {
                        urlImage = [[UrlImage alloc] initWithUrl:pictureUrlString forImageView:fbImage1];
                        [[UrlImageManager getInstance] insertImageToCache:fbid image:urlImage];
                    }
                    break;
                    
                case 1:
                    fbName2.text = fbName;
                    if (urlImage)
                    {
                        [fbImage2 setImage:[urlImage image]];
                    }
                    else
                    {
                        urlImage = [[UrlImage alloc] initWithUrl:pictureUrlString forImageView:fbImage2];
                        [[UrlImageManager getInstance] insertImageToCache:fbid image:urlImage];
                    }
                    break;
                    
                case 2:
                    fbName3.text = fbName;
                    if (urlImage)
                    {
                        [fbImage3 setImage:[urlImage image]];
                    }
                    else
                    {
                        urlImage = [[UrlImage alloc] initWithUrl:pictureUrlString forImageView:fbImage3];
                        [[UrlImageManager getInstance] insertImageToCache:fbid image:urlImage];
                    }
                    break;
                    
                case 3:
                    fbName4.text = fbName;
                    if (urlImage)
                    {
                        [fbImage4 setImage:[urlImage image]];
                    }
                    else
                    {
                        urlImage = [[UrlImage alloc] initWithUrl:pictureUrlString forImageView:fbImage4];
                        [[UrlImageManager getInstance] insertImageToCache:fbid image:urlImage];
                    }
                    break;
                    
                case 4:
                    fbName5.text = fbName;
                    if (urlImage)
                    {
                        [fbImage5 setImage:[urlImage image]];
                    }
                    else
                    {
                        urlImage = [[UrlImage alloc] initWithUrl:pictureUrlString forImageView:fbImage5];
                        [[UrlImageManager getInstance] insertImageToCache:fbid image:urlImage];
                    }
                    break;
                    
                default:
                    break;
            }
            index++;
        }
        NSUInteger otherSalesNum = [[PlayerSales getInstance] nonNamedCount];
        if (otherSalesNum > 0)
        {
            mainText.text = [NSString stringWithFormat:@"and %d others traded with you. You earned %d bucks total!",
                             otherSalesNum, [[PlayerSales getInstance] bucks]];
        }
        else
        {
            mainText.text = [NSString stringWithFormat:@"traded with you. You earned %d bucks total!",
                             [[PlayerSales getInstance] bucks]];
        }
    }
    else
    {
        NSUInteger otherSalesNum = [[PlayerSales getInstance] nonNamedCount];
        mainText.text = [NSString stringWithFormat:@"%d players traded with you. You earned %d bucks total!",
                         otherSalesNum, [[PlayerSales getInstance] bucks]];
    }
}

- (IBAction)didPressOK:(id)sender
{
    [[PlayerSales getInstance] resolveSales];
    [self.navigationController popToRightViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
