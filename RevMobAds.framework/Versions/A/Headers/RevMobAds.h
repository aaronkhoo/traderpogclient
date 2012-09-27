#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "RevMobAdsDelegate.h"

#import "RevMobAdLink.h"
#import "RevMobBannerView.h"
#import "RevMobBanner.h"
#import "RevMobButton.h"
#import "RevMobFullscreen.h"
#import "RevMobPopup.h"


typedef enum {
    RevMobAdsTestingModeOff = 0,
    RevMobAdsTestingModeWithAds,
    RevMobAdsTestingModeWithoutAds
} RevMobAdsTestingMode;


/**
 This is the main class to start using RevMob Ads.
 You can use the standard facade methods or the alternative object orientaded version.

 */
@interface RevMobAds : NSObject{

}

@property (nonatomic, assign) id<RevMobAdsDelegate> delegate;
@property (nonatomic, assign) RevMobAdsTestingMode testingMode;

#pragma mark - Alternative use

///---------------------------------------------------------------------------------------
/// @name Object Orientated methods (alterenative use)
///---------------------------------------------------------------------------------------

/**
 @see initWithAppId:delagate:testingMode:
 */
- (RevMobAds *)initWithAppId:(NSString *)anAppId delagate:(id<RevMobAdsDelegate>)aDelagate;

/**
 This method is necessary to get the ads objects.

 It must be the first method called on the application:didFinishLaunchingWithOptions: method of the application delegate.

 Example of Usage:

     - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

         RevMobAds *revmob = [[[RevMobAds alloc] initWithAppId:appID delagate:self testingMode:RevMobAdsTestingModeOff]];

         self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];

         // Override point for customization after application launch.
     }

 @param appID: You can collect your App ID at http://revmob.com by looking up your apps.
 @param delegate: You can receive notifications when there is some error.
 @param testingMode: You can set the tesing mode here, you can use this constants:
     RevMobAdsTestingModeOff, RevMobAdsTestingModeWithAds or RevMobAdsTestingModeWithoutAds.
 */
- (RevMobAds *)initWithAppId:(NSString *)anAppId delagate:(id<RevMobAdsDelegate>)aDelagate testingMode:(RevMobAdsTestingMode)testingMode;

/**
 This is the fabric of RevMobFullscreen ad object

 Example of Usage:

    RevMobAds *revmob = [[[RevMobAds alloc] initWithAppId:appID delagate:self]];
    RevMobFullscreen *fullscreen = [revmob fullscreen];
 
 @return RevMobFullscreen object.
*/
- (RevMobFullscreen *)fullscreen;

/**
 This is the fabric of RevMobFullscreen ad object

 Example of Usage:

     RevMobAds *revmob = [[[RevMobAds alloc] initWithAppId:@"appID" delagate:self]];
     RevMobFullscreen *fullscreen = [revmob fullscreenWithPlacementId:@"placementId"];


 @param placementId: Optional parameter that identify the placement of your ad,
 you can collect your ids at http://revmob.com by looking up your apps. Can be nil.
 @return RevMobFullscreen object.
 */
- (RevMobFullscreen *)fullscreenWithPlacementId:(NSString *)placementId;

/**
 This is the fabric of RevMobBannerView ad object

 Example of Usage:
 
     RevMobAds *revmob = [[[RevMobAds alloc] initWithAppId:appID delagate:self]];
     RevMobBannerView *bannerView = [revmob bannerView];
 
  @return RevMobBannerView object. 
*/
- (RevMobBannerView *)bannerView;

/**
 This is the fabric of RevMobBannerView ad object

 Example of Usage:

     RevMobAds *revmob = [[[RevMobAds alloc] initWithAppId:@"appID" delagate:self]];
     RevMobBannerView *bannerView = [revmob bannerViewWithPlacementId:@"placementId"];

 @param placementId: Optional parameter that identify the placement of your ad,
 you can collect your ids at http://revmob.com by looking up your apps. Can be nil.
 @return RevMobBannerView object.
 */
- (RevMobBannerView *)bannerViewWithPlacementId:(NSString *)placementId;


/**
 This is the fabric of RevMobBanner ad object

 Example of Usage:
 
     RevMobAds *revmob = [[[RevMobAds alloc] initWithAppId:appID delagate:self]];
     RevMobBanner *banner = [revmob banner];
 
  @return RevMobBanner object.
*/
- (RevMobBanner *)banner;

/**
 This is the fabric of RevMobBanner ad object

 Example of Usage:

     RevMobAds *revmob = [[[RevMobAds alloc] initWithAppId:@"appID" delagate:self]];
     RevMobBanner *banner = [revmob bannerWithPlacementId:@"placementId"];

 @param placementId: Optional parameter that identify the placement of your ad,
 you can collect your ids at http://revmob.com by looking up your apps. Can be nil.
 @return RevMobBanner object.
 */
- (RevMobBanner *)bannerWithPlacementId:(NSString *)placementId;


/**
 This is the fabric of button ad object

 Example of Usage:
 
     RevMobAds *revmob = [[[RevMobAds alloc] initWithAppId:appID delagate:self]];
     RevMobButton *button = [revmob button];
 
  @return RevMobButton object.
*/
- (RevMobButton *)button;

/**
 This is the fabric of button ad object

 Example of Usage:

     RevMobAds *revmob = [[[RevMobAds alloc] initWithAppId:@"appID" delagate:self]];
     RevMobButton *button = [revmob buttonWithPlacementId:@"placementId"];

 @param placementId: Optional parameter that identify the placement of your ad,
 you can collect your ids at http://revmob.com by looking up your apps. Can be nil.
 @return RevMobButton object.
 */
- (RevMobButton *)buttonWithPlacementId:(NSString *)placementId;


/**
 This is the fabric of adLink object

 Example of Usage:
 
     RevMobAds *revmob = [[[RevMobAds alloc] initWithAppId:appID delagate:self]];
     RevMobAdLink *adLink = [revmob adLink];
 
  @return RevMobAdLink object.
*/
- (RevMobAdLink *)adLink;

/**
 This is the fabric of adLink object

 Example of Usage:

     RevMobAds *revmob = [[[RevMobAds alloc] initWithAppId:@"appID" delagate:self]];
     RevMobAdLink *adLink = [revmob adLinkWithPlacementId:@"placementId"];

 @param placementId: Optional parameter that identify the placement of your ad,
 you can collect your ids at http://revmob.com by looking up your apps. Can be nil.
 @return RevMobAdLink object.
 */
- (RevMobAdLink *)adLinkWithPlacementId:(NSString *)placementId;

/**
 This is the fabric of popup ad object

 Example of Usage:
 
     RevMobAds *revmob = [[[RevMobAds alloc] initWithAppId:appID delagate:self]];
     RevMobPopup *popup = [revmob popup];
 
  @return RevMobPopup object.
*/
- (RevMobPopup *)popup;

/**
 This is the fabric of popup ad object

 Example of Usage:

     RevMobAds *revmob = [[[RevMobAds alloc] initWithAppId:@"appID" delagate:self]];
     RevMobPopup *popup = [revmob popupWithPlacementId:@"placementId"];

 @param placementId: Optional parameter that identify the placement of your ad,
 you can collect your ids at http://revmob.com by looking up your apps. Can be nil.
 @return RevMobPopup object.
 */
- (RevMobPopup *)popupWithPlacementId:(NSString *)placementId;



#pragma mark - Facade -


#pragma mark - Start Session

///---------------------------------------------------------------------------------------
/// @name Default Facade methods
///---------------------------------------------------------------------------------------


/**
 @see startSessionWithAppID:testingMode:
 */
+ (void) startSessionWithAppID:(NSString *)appID;

/**
 This method is necessary to set your App ID and start your session.
 
 It must be the first method called on the application:didFinishLaunchingWithOptions: method of the application delegate.

 Example of Usage:
 
     - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
 
         [RevMobAds startSessionWithAppID:REVMOB_ID];
 
         self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
         // Override point for customization after application launch.
     }

 @param appID: You can collect your App ID at http://revmob.com by looking up your apps.
 @param testingMode: You can set the tesing mode here, you can use this constants:
 RevMobAdsTestingModeOff, RevMobAdsTestingModeWithAds or RevMobAdsTestingModeWithoutAds.
*/
+ (void) startSessionWithAppID:(NSString *)appID testingMode:(RevMobAdsTestingMode)testingMode;

#pragma mark - Fullscreen


/**
 @see showFullscreenAdWithDelegate:withSpecificOrientations:
*/
+ (void) showFullscreenAd;


/**
 @see showFullscreenAdWithDelegate:withSpecificOrientations:
*/
+ (void) showFullscreenAdWithDelegate:(NSObject<RevMobAdsDelegate> *)delegate;


/**
 Example of Usage:
 ---------------------------------------------
 
    [RevMobAds showFullscreenAdWithDelegate:nil withSpecificOrientations:nil];
 
 
 Example of Usage using specific orientations:
 ---------------------------------------------
 
    [RevMobAds showFullscreenAdWithDelegate:nil withSpecificOrientations:UIInterfaceOrientationPortrait, UIInterfaceOrientationLandscapeLeft, nil];
 

 Example of Usage using delegate:
 --------------------------------
 
** MyRevMobAdsDelegate.h
 
    #import <Foundation/Foundation.h>
    #import "RevMobAdsDelegate.h"
 
    @interface MyRevMobAdsDelegate : NSObject<RevMobAdsDelegate>
    @end
 
 
** MyRevMobAdsDelegate.m
 
    @implementation MyRevMobAdsDelegate
 
     - (void) revmobAdDidReceive {
         NSLog(@"[RevMob Sample App] Ad loaded.");
     }
 
     - (void) revmobAdDidFailWithError:(NSError *)error {
         NSLog(@"[RevMob Sample App] Ad failed.");
     }
 
     - (void) revmobUserClickedInTheCloseButton {
         NSLog(@"[RevMob Sample App] User clicked in the close button");
     }
 
     - (void) revmobUserClickedInTheAd {
         NSLog(@"[RevMob Sample App] User clicked in the Ad");
     }
     @end
 
 
** MyViewController.m
 
     #import "RevMobAds.h"
     #import "RevMobAdsDelegate.h"
 
     @implementation MyViewController
 
     - (void)someMethod {
         MyRevMobAdsDelegate *delegate = [[MyRevMobAdsDelegate alloc] init];
         [RevMobAds showFullscreenAdWithDelegate:delegate withSpecificOrientations:nil];
         [delegate release];
     }
 
 @param delegate: You can receive notifications when the Ad is or is not loaded, when the user click in the close button or in the Ad. It may be nil.
 @param orientations: You can define to which orientations the fullscreen will rotate. It may be nil.
*/
+ (void) showFullscreenAdWithDelegate:(NSObject<RevMobAdsDelegate> *)delegate withSpecificOrientations:(UIInterfaceOrientation)orientations, ... NS_REQUIRES_NIL_TERMINATION;


/**
 You can use this method if you rather to use NSArray instead of Variable argument list.
 
 @see showFullscreenAdWithDelegate:withSpecificOrientations:, ...
*/
+ (void) showFullscreenAdWithSpecificOrientations:(NSArray *)orientations withDelegate:(NSObject<RevMobAdsDelegate> *)delegate;


#pragma mark - Fullscreen with pre-load

/**
 Load a Fullscreen Ad without showing it. To show the loaded Ad you have to call any of the showFullscreen
 methods. You may call this method in the beginning of the game or level to show the ad in the future.

 Example of Usage:
 ---------------------------------------------

     [RevMobAds loadFullscreen];


 @see showFullscreenAd
 @see isLoadedFullscreenAd
 @see releaseFullscreenAd
 */
+ (void) loadFullscreenAd;

/**
 If you did not call the loadFullscreenAd method, nothing will happen and it will return NO.
 
 @return Return YES if the previously loaded Ad (by the method loadFullscreenAd) is loaded. Else return NO.		 
 
 @see loadFullscreenAd
 @see showFullscreenAd
 @see releaseFullscreenAd
*/
+ (BOOL) isLoadedFullscreenAd;


/**
 Delete and release the Ad that was previously loaded by the method loadFullscreenAd.
 If you did not call the loadFullscreenAd method, nothing will happen.
 
 @see loadFullscreenAd
 @see isLoadedFullscreenAd
 @see showFullscreenAd
*/
+ (void) releaseFullscreenAd;


#pragma mark - Banner

/**
 @see showBannerAdWithFrame:withDelegate:withSpecificOrientations:
*/
+ (void) showBannerAd;


/**
 @see showBannerAdWithFrame:withDelegate:withSpecificOrientations:
*/
+ (void) showBannerAdWithDelegate:(NSObject<RevMobAdsDelegate> *)delegate;


/**
 @see showBannerAdWithFrame:withDelegate:withSpecificOrientations:
*/
+ (void) showBannerAdWithDelegate:(NSObject<RevMobAdsDelegate> *)delegate withSpecificOrientations:(UIInterfaceOrientation)orientations, ... NS_REQUIRES_NIL_TERMINATION;


/**
 @see showBannerAdWithFrame:withDelegate:withSpecificOrientations:
*/
+ (void) showBannerAdWithFrame:(CGRect)frame withDelegate:(NSObject<RevMobAdsDelegate> *)delegate;


/**
 If frame is nil, the banner will be stucked to the bottom, with width 100% and height 50 points, no matter the orientation.
 Else, you can customize the location and size of the banner, but the minimum accepted size is 320,50. In this case, the developer has the 
 responsibility to adjust the banner frame on rotation.
 
 Example of Usage:
 -----------------
     [RevMobAds showBannerAdWithFrame:CGRectNull withDelegate:nil withSpecificOrientations:nil];
 
 Example of Usage using custom frame:
 ------------------------------------
     [RevMobAds showBannerAdWithFrame:CGRectMake(0, 0, 320, 50) withDelegate:nil withSpecificOrientations:nil];
 
 Example of Usage using specific orientations:
 ---------------------------------------------
     [RevMobAds showBannerAdWithFrame:CGRectNull withDelegate:nil withSpecificOrientations:UIInterfaceOrientationPortraitUpsideDown, UIInterfaceOrientationLandscapeRight, nil];

 
 @param frame: A CGRect that will be used to draw the banner. The 0,0 point of the coordinate system will be always in the top-left corner.  It may be CGRectNull.
 @param delegate: You can receive notifications when the Ad is or is not loaded. It may be nil.
 @param orientations: You can define to which orientations the banner will rotate. It may be nil.

 @see hideBannerAd
*/
+ (void) showBannerAdWithFrame:(CGRect)frame withDelegate:(NSObject<RevMobAdsDelegate> *)delegate withSpecificOrientations:(UIInterfaceOrientation)orientations, ... NS_REQUIRES_NIL_TERMINATION;


/**
 You can use this method if you rather to use NSArray instead of Variable argument list.
 
 @see showBannerAdWithFrame:withDelegate:withSpecificOrientations:
*/
+ (void) showBannerAdWithFrame:(CGRect)frame withSpecificOrientations:(NSArray *)orientations withDelegate:(NSObject<RevMobAdsDelegate> *)delegate;


/**
 Hide a banner.
 
 @see showBannerAdWithFrame:withDelegate:withSpecificOrientations:
*/
+ (void) hideBannerAd;

/**
 Hide and release a banner.
  
 @see showBannerAdWithFrame:withDelegate:withSpecificOrientations:
*/
+ (void) deactivateBannerAd;

#pragma mark - Ad Link

/**
 Open an Ad link in the iTunes store. You can call this method, for example, when the user clicks in a button "Get More Free Games".
 
*/
+ (void) openAdLink;

#pragma mark - Ad Button

/**
 @see buttonAdWithDelegate:withFrame:
*/
+ (UIButton *) buttonAd;

/**
 @see buttonAdWithDelegate:withFrame:
 */
+ (UIButton *) buttonAdWithDelegate:(NSObject<RevMobAdsDelegate> *)delegate;

/**
 A button properly configured to offer more free games to your users.

 You can load the button in the viewDidLoaded method of your ViewControler. If wanted the button apearence can be changed the same way as a regular UIButton.
 
 Example:
 
     - (void)viewDidLoaded {
         CGFloat width = floorf(self.view.frame.size.width*.8);
         CGFloat height = 80;
         CGFloat offset = floorf((self.view.frame.size.width*.8 - width)/2);
         CGRect frame = CGrectMake(offset,offset,height,width);
         UIButton *button = [RevMobAds buttonAdWithDelegate:self withFrame:frame];
         [self.view addSubview:button];

         // Optional title change
         [button setTitle:@"More Free Games" forState:UIControlStateNormal];
         // Optional color changes
         UIImage *background1 = [self imageWithColor:[UIColor grayColor]];
         UIImage *background2 = [self imageWithColor:[UIColor lightGrayColor]];
         [button setBackgroundImage:background1 forState:UIControlStateNormal];
         [button setBackgroundImage:background2 forState:UIControlStateSelected];
         // Optional rounded corner changes, require #import <QuartzCore/QuartzCore.h>
         button.layer.cornerRadius = 5;
         button.clipsToBounds = YES;
     }

 @param delegate: You can receive notifications when the Ad is clicked. It may be nil.
 @param frame: A CGRect that will be used to draw the banner. The 0,0 point of the coordinate system will be always in the top-left corner.  It may be CGRectNull.

 @return A button properly configured to show more games for yours users.
 */
+ (UIButton *) buttonAdWithDelegate:(NSObject<RevMobAdsDelegate> *)delegate withFrame:(CGRect)frame;

#pragma mark - Popup

/**
 @see showPopupWithDelegate:
*/
+ (void) showPopup;


/** 
 This will show a popup ad unit.
 
 You can call this on: Delegate, UIViewController or any other type of object.
 Performance: You will be paid primarily by the number of installs your app generates and 
 sometimes by the number of clicks on the popups. Impressions shouldn't provide revenue.
 Deactivation: Not necessary.
 When: Best to show when app opens, but can be shown whenever you want.
 
 Example:
 
     - (void)applicationDidBecomeActive:(UIApplication *)application {
        [RevMobAds showPopupWithDelegate:nil];
     }
 
     - (void)viewDidLoad {
        [super viewDidLoad];
        [RevMobAds showPopupWithDelegate:nil];
     }
 
 *** any other object or method will work
 
 @param delegate: You can receive notifications when the Ad is or is not loaded. It may be nil.
*/
+ (void) showPopupWithDelegate:(NSObject<RevMobAdsDelegate> *)delegate;

#pragma mark - other methods

/**
 This method is useful to send us information about your environment, which facilitates we identifing what is going on.
*/
+ (void) printEnvironmentInformationWithAppID:(NSString *)appID;

@end
