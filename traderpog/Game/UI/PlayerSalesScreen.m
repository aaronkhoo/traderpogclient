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
#import "CircleButton.h"
#import "PogUIUtility.h"
#import "GameColors.h"
#import "GameAnim.h"

static NSString* const kFbPictureUrl = @"https://graph.facebook.com/%@/picture";
static const float kBorderWidth = 6.0f;
static const float kOkCircleBorderWidth = 6.0f;
static const float kBorderCornerRadius = 8.0f;

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

- (void) dealloc
{
    NSLog(@"PlayerSalesScreen dealloc");
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    // layout
    [PogUIUtility setBorderOnView:self.contentView
                            width:kBorderWidth
                            color:[GameColors bgColorPlayerSalesWithAlpha:1.0f]
                     cornerRadius:kBorderCornerRadius];
    [self.contentView setBackgroundColor:[GameColors bgColorPlayerSalesWithAlpha:1.0f]];
    [self.okCircle setBorderColor:[GameColors bgColorPlayerSalesWithAlpha:1.0f]];
    [self.okCircle setBorderWidth:kOkCircleBorderWidth];
    [self.okCircle setButtonTarget:self action:@selector(didPressOK:)];
    [[GameAnim getInstance] refreshImageView:[self coinImageView] withClipNamed:@"coin_shimmer"];
    [self.coinImageView startAnimating];

    // content
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
            mainText.text = [NSString stringWithFormat:@"and %d others traded with you. \nYou earned a total of",
                             otherSalesNum];
        }
        else
        {
            mainText.text = @"traded with you. \nYou earned a total of";
        }
    }
    else
    {
        NSUInteger otherSalesNum = [[PlayerSales getInstance] nonNamedCount];
        mainText.text = [NSString stringWithFormat:@"%d players \ntraded with you. \nYou earned a total of",
                         otherSalesNum];
    }
    NSString* earningsText = [PogUIUtility commaSeparatedStringFromUnsignedInt:[[PlayerSales getInstance] bucks]];
    [self.earningsLabel setText:earningsText];
}

- (void)didPressOK:(id)sender
{
    [[PlayerSales getInstance] resolveSales];
    [self.navigationController popToRightViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setEarningsLabel:nil];
    [self setCoinImageView:nil];
    [self setOkCircle:nil];
    [self setContentView:nil];
    [super viewDidUnload];
}
@end
