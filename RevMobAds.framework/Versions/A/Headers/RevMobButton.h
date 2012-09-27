#import <Foundation/Foundation.h>
#import "RevMobAdvertisement.h"
#import "RevMobAdsDelegate.h"

/**
 Subclass of UIButton, you can use in your app just as a regular UIButton.

 You should alter just the appearance of it.

 When the button is clicked a RevMobAdLink is used, so the behaviour is the same
 of the adLink. The intention is to facilitate the implementation of a "More games"
 button.
 */
@interface RevMobButton : UIButton <RevMobAdvertisement, RevMobAdsDelegate>

/**
 The delegate setted on this property is called when ad related events happend, see
 RevMobAdsDelegate for mode details.
 */
@property(nonatomic, assign) id<RevMobAdsDelegate> delegate;

@end
