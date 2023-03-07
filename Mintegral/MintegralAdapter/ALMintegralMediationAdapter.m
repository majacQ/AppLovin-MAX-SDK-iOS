//
//  ALMintegralMediationAdapter.m
//  AppLovinSDK
//

#import "ALMintegralMediationAdapter.h"
#import <MTGSDK/MTGSDK.h>
#import <MTGSDK/MTGErrorCodeConstant.h>
#import <MTGSDKBidding/MTGBiddingSDK.h>
#import <MTGSDKInterstitialVideo/MTGBidInterstitialVideoAdManager.h>
#import <MTGSDKInterstitialVideo/MTGInterstitialVideoAdManager.h>
#import <MTGSDKReward/MTGRewardAdManager.h>
#import <MTGSDKReward/MTGBidRewardAdManager.h>
#import <MTGSDKBanner/MTGBannerAdView.h>
#import <MTGSDKBanner/MTGBannerAdViewDelegate.h>
#import <MTGSDKSplash/MTGSplashAD.h>

#define ADAPTER_VERSION @"7.3.3.0.0"

// List of Mintegral error codes not defined in API, but in their docs
//
// http://cdn-adn.rayjump.com/cdn-adn/v2/markdown_v2/index.html?file=sdk-m_sdk-ios&lang=en#faqs
//
#define EXCEPTION_RETURN_EMPTY -1 // ads no fill
#define EXCEPTION_TIMEOUT -9 // request timeout
#define EXCEPTION_IV_RECALLNET_INVALIDATE -1904 // The network status at the time of the request is incorrect. Generally， because of the SDK initialization is not completed yet when the request has been sent.
#define EXCEPTION_SIGN_ERROR -10 // AppID and appKey do not match correctly
#define EXCEPTION_UNIT_NOT_FOUND -1201 // Can not find the unitID in dashboard
#define EXCEPTION_UNIT_ID_EMPTY -1202 // unitID is empty
#define EXCEPTION_UNIT_NOT_FOUND_IN_APP -1203 // Can not find the unitID of the appID
#define EXCEPTION_UNIT_ADTYPE_ERROR -1205 // The adtype of the unitID is wrong
#define EXCEPTION_APP_ID_EMPTY -1301 // appID is empty
#define EXCEPTION_APP_NOT_FOUND -1302 // Can not find the appId

@interface ALMintegralMediationAdapterInterstitialDelegate : NSObject <MTGInterstitialVideoDelegate, MTGBidInterstitialVideoDelegate>
@property (nonatomic,   weak) ALMintegralMediationAdapter *parentAdapter;
@property (nonatomic, strong) id<MAInterstitialAdapterDelegate> delegate;
- (instancetype)initWithParentAdapter:(ALMintegralMediationAdapter *)parentAdapter andNotify:(id<MAInterstitialAdapterDelegate>)delegate;
@end

@interface ALMintegralMediationAdapterAppOpenAdDelegate : NSObject <MTGSplashADDelegate>
@property (nonatomic,   weak) ALMintegralMediationAdapter *parentAdapter;
@property (nonatomic, strong) id<MAAppOpenAdapterDelegate> delegate;
- (instancetype)initWithParentAdapter:(ALMintegralMediationAdapter *)parentAdapter andNotify:(id<MAAppOpenAdapterDelegate>)delegate;
@end

@interface ALMintegralMediationAdapterRewardedDelegate : NSObject <MTGRewardAdLoadDelegate, MTGRewardAdShowDelegate>
@property (nonatomic,   weak) ALMintegralMediationAdapter *parentAdapter;
@property (nonatomic, strong) id<MARewardedAdapterDelegate> delegate;
@property (nonatomic, assign, getter=hasGrantedReward) BOOL grantedReward;
- (instancetype)initWithParentAdapter:(ALMintegralMediationAdapter *)parentAdapter andNotify:(id<MARewardedAdapterDelegate>)delegate;
@end

@interface ALMintegralMediationAdapterBannerViewDelegate : NSObject <MTGBannerAdViewDelegate>
@property (nonatomic,   weak) ALMintegralMediationAdapter *parentAdapter;
@property (nonatomic, strong) id<MAAdViewAdapterDelegate> delegate;
- (instancetype)initWithParentAdapter:(ALMintegralMediationAdapter *)parentAdapter andNotify:(id<MAAdViewAdapterDelegate>)delegate;
@end

@interface ALMintegralMediationAdapterNativeAdDelegate : NSObject <MTGNativeAdManagerDelegate, MTGBidNativeAdManagerDelegate, MTGMediaViewDelegate>
@property (nonatomic,   weak) ALMintegralMediationAdapter *parentAdapter;
@property (nonatomic, strong) NSDictionary<NSString *, id> *serverParameters;
@property (nonatomic, strong) id<MANativeAdAdapterDelegate> delegate;
@property (nonatomic, strong) NSString *unitId;
@property (nonatomic, strong) NSString *placementId;
- (instancetype)initWithParentAdapter:(ALMintegralMediationAdapter *)parentAdapter parameters:(id<MAAdapterResponseParameters>)parameters andNotify:(id<MANativeAdAdapterDelegate>)delegate;
@end

@interface ALMintegralMediationAdapterNativeAdViewDelegate : NSObject <MTGNativeAdManagerDelegate, MTGBidNativeAdManagerDelegate, MTGMediaViewDelegate>
@property (nonatomic,   weak) ALMintegralMediationAdapter *parentAdapter;
@property (nonatomic,   weak) MAAdFormat *format;
@property (nonatomic, strong) NSDictionary<NSString *, id> *serverParameters;
@property (nonatomic, strong) id<MAAdViewAdapterDelegate> delegate;
@property (nonatomic, strong) NSString *unitId;
@property (nonatomic, strong) NSString *placementId;
- (instancetype)initWithParentAdapter:(ALMintegralMediationAdapter *)parentAdapter format:(MAAdFormat *)format parameters:(id<MAAdapterResponseParameters>)parameters andNotify:(id<MAAdViewAdapterDelegate>)delegate;
@end

@interface MAMintegralNativeAd : MANativeAd
@property (nonatomic, weak) ALMintegralMediationAdapter *parentAdapter;
- (instancetype)initWithParentAdapter:(ALMintegralMediationAdapter *)parentAdapter adFormat:(MAAdFormat *)format builderBlock:(NS_NOESCAPE MANativeAdBuilderBlock)builderBlock;
- (instancetype)initWithFormat:(MAAdFormat *)format builderBlock:(NS_NOESCAPE MANativeAdBuilderBlock)builderBlock NS_UNAVAILABLE;
@end

@interface ALMintegralMediationAdapter ()

@property (nonatomic, strong) MTGBidInterstitialVideoAdManager *bidInterstitialVideoManager;
@property (nonatomic, strong) MTGInterstitialVideoAdManager *interstitialVideoManager;
@property (nonatomic, strong) MTGSplashAD *appOpenAd;
@property (nonatomic, strong) MTGBannerAdView *bannerAdView;
@property (nonatomic, strong) MTGBidNativeAdManager *bidNativeAdManager;
@property (nonatomic, strong) MTGBidNativeAdManager *bidNativeAdViewManager;
@property (nonatomic, strong) MTGCampaign *nativeAdCampaign;
@property (nonatomic,   weak) UIView *maxNativeAdContainer;
@property (nonatomic, strong) NSArray<UIView *> *clickableViews;

@property (nonatomic, strong) ALMintegralMediationAdapterInterstitialDelegate *interstitialDelegate;
@property (nonatomic, strong) ALMintegralMediationAdapterAppOpenAdDelegate *appOpenAdDelegate;
@property (nonatomic, strong) ALMintegralMediationAdapterRewardedDelegate *rewardedDelegate;
@property (nonatomic, strong) ALMintegralMediationAdapterBannerViewDelegate *bannerDelegate;
@property (nonatomic, strong) ALMintegralMediationAdapterNativeAdDelegate *nativeAdDelegate;
@property (nonatomic, strong) ALMintegralMediationAdapterNativeAdViewDelegate *nativeAdViewDelegate;

@end

@implementation ALMintegralMediationAdapter
static NSTimeInterval const kDefaultImageTaskTimeoutSeconds = 5.0; // Mintegral ad load timeout is 10s, so this is 5s.

#pragma mark - MAAdapter Methods

- (void)initializeWithParameters:(id<MAAdapterInitializationParameters>)parameters completionHandler:(void (^)(MAAdapterInitializationStatus, NSString *_Nullable))completionHandler
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        NSString *appId = [parameters.serverParameters al_stringForKey: @"app_id"];
        NSString *appKey = [parameters.serverParameters al_stringForKey: @"app_key"];
        [self log: @"Initializing Mintegral SDK with app id: %@ and app key: %@...", appId, appKey];
        
        MTGSDK *mtgSDK = [MTGSDK sharedInstance];
        
        // Must be called before -[MTGSDK setAppID:ApiKey:] - GDPR status can only be set before SDK initialization
        NSNumber *hasUserConsent = [self privacySettingForSelector: @selector(hasUserConsent) fromParameters: parameters];
        if ( hasUserConsent )
        {
            mtgSDK.consentStatus = hasUserConsent.boolValue;
        }
        
        if ( ALSdk.versionCode >= 61100 )
        {
            // Has to be _before_ their SDK init as well
            NSNumber *isDoNotSell = [self privacySettingForSelector: @selector(isDoNotSell) fromParameters: parameters];
            if ( isDoNotSell && isDoNotSell.boolValue )
            {
                mtgSDK.doNotTrackStatus = YES;
            }
        }
        
        // Has to be _before_ their SDK init as well
        NSNumber *isAgeRestrictedUser = [self privacySettingForSelector: @selector(isAgeRestrictedUser) fromParameters: parameters];
        if ( isAgeRestrictedUser )
        {
            [mtgSDK setCoppa: isAgeRestrictedUser.boolValue ? MTGBoolYes : MTGBoolNo];
        }
        else
        {
            [mtgSDK setCoppa: MTGBoolUnknown];
        }
        
        [mtgSDK setAppID: appId ApiKey: appKey];
    });
    
    completionHandler(MAAdapterInitializationStatusDoesNotApply, nil);
}

- (nullable NSNumber *)privacySettingForSelector:(SEL)selector fromParameters:(id<MAAdapterParameters>)parameters
{
    // Use reflection because compiled adapters have trouble fetching `BOOL` from old SDKs and `NSNumber` from new SDKs (above 6.14.0)
    NSMethodSignature *signature = [[parameters class] instanceMethodSignatureForSelector: selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature: signature];
    [invocation setSelector: selector];
    [invocation setTarget: parameters];
    [invocation invoke];
    
    // Privacy parameters return nullable `NSNumber` on newer SDKs
    if ( ALSdk.versionCode >= 6140000 )
    {
        NSNumber *__unsafe_unretained value;
        [invocation getReturnValue: &value];
        
        return value;
    }
    // Privacy parameters return BOOL on older SDKs
    else
    {
        BOOL rawValue;
        [invocation getReturnValue: &rawValue];
        
        return @(rawValue);
    }
}

- (NSString *)SDKVersion
{
    return [MTGSDK sdkVersion];
}

- (NSString *)adapterVersion
{
    return ADAPTER_VERSION;
}

- (void)destroy
{
    self.bidInterstitialVideoManager.delegate = nil;
    self.bidInterstitialVideoManager = nil;
    
    self.interstitialVideoManager.delegate = nil;
    self.interstitialVideoManager = nil;
    
    self.appOpenAd.delegate = nil;
    self.appOpenAd = nil;
    
    [self.bannerAdView destroyBannerAdView];
    self.bannerAdView.delegate = nil;
    self.bannerAdView = nil;
    
    [self.bidNativeAdManager unregisterView: self.maxNativeAdContainer clickableViews: self.clickableViews];
    self.bidNativeAdManager.delegate = nil;
    self.bidNativeAdManager = nil;
    
    [self.bidNativeAdViewManager unregisterView: self.maxNativeAdContainer clickableViews: self.clickableViews];
    self.bidNativeAdViewManager.delegate = nil;
    self.bidNativeAdViewManager = nil;
    
    self.nativeAdCampaign = nil;
    
    self.interstitialDelegate = nil;
    self.appOpenAdDelegate = nil;
    self.rewardedDelegate = nil;
    self.bannerDelegate = nil;
    self.nativeAdDelegate = nil;
    self.nativeAdViewDelegate = nil;
}

#pragma mark - Signal Collection

- (void)collectSignalWithParameters:(id<MASignalCollectionParameters>)parameters andNotify:(id<MASignalCollectionDelegate>)delegate
{
    [self log: @"Collecting signal..."];
    
    NSDictionary<NSString *, id> *bidInfo = @{@"placementId" : parameters.serverParameters[@"placement_id"] ?: @"",
                                              @"unitId" : parameters.adUnitIdentifier ?: @"",
                                              @"adType" : @([self toMintegralAdType: parameters.adFormat])};
    
    NSString *signal = [MTGBiddingSDK buyerUIDWithDictionary: bidInfo];
    [delegate didCollectSignal: signal];
}

#pragma mark - MAInterstitialAdapter Methods

- (void)loadInterstitialAdForParameters:(id<MAAdapterResponseParameters>)parameters andNotify:(id<MAInterstitialAdapterDelegate>)delegate
{
    // Overwritten by `mute_state` setting, unless `mute_state` is disabled
    BOOL shouldUpdateMuteState = [parameters.serverParameters al_containsValueForKey: @"is_muted"]; // Introduced in 6.10.0
    BOOL muted = [parameters.serverParameters al_numberForKey: @"is_muted"].boolValue;
    
    self.interstitialDelegate = [[ALMintegralMediationAdapterInterstitialDelegate alloc] initWithParentAdapter: self andNotify: delegate];
    
    NSString *unitId = parameters.thirdPartyAdPlacementIdentifier;
    NSString *placementId = [parameters.serverParameters al_stringForKey: @"placement_id"];
    
    if ( [parameters.bidResponse al_isValidString] )
    {
        [self log: @"Loading bidding interstitial for unit id: %@ and placement id: %@...", unitId, placementId];
        
        self.bidInterstitialVideoManager = [[MTGBidInterstitialVideoAdManager alloc] initWithPlacementId: placementId
                                                                                                  unitId: unitId
                                                                                                delegate: self.interstitialDelegate];
        
        // Update mute state if configured by backend
        if ( shouldUpdateMuteState ) self.bidInterstitialVideoManager.playVideoMute = muted;
        
        [self.bidInterstitialVideoManager loadAdWithBidToken: parameters.bidResponse];
    }
    else
    {
        [self log: @"Loading mediated interstitial ad for unit id: %@ and placement id: %@...", unitId, placementId];
        
        self.interstitialVideoManager = [[MTGInterstitialVideoAdManager alloc] initWithPlacementId: placementId
                                                                                            unitId: unitId
                                                                                          delegate: self.interstitialDelegate];
        
        if ( [self.interstitialVideoManager isVideoReadyToPlayWithPlacementId: placementId unitId: unitId] )
        {
            [self log: @"A mediated interstitial ad is ready already"];
            [delegate didLoadInterstitialAd];
        }
        else
        {
            // Update mute state if configured by backend
            if ( shouldUpdateMuteState ) self.interstitialVideoManager.playVideoMute = muted;
            
            [self.interstitialVideoManager loadAd];
        }
    }
}

- (void)showInterstitialAdForParameters:(id<MAAdapterResponseParameters>)parameters andNotify:(id<MAInterstitialAdapterDelegate>)delegate
{
    NSString *unitId = parameters.thirdPartyAdPlacementIdentifier;
    NSString *placementId = [parameters.serverParameters al_stringForKey: @"placement_id"];
    
    if ( [self.bidInterstitialVideoManager isVideoReadyToPlayWithPlacementId: placementId unitId: unitId] )
    {
        [self log: @"Showing bidding interstitial..."];
        
        UIViewController *presentingViewController;
        if ( ALSdk.versionCode >= 11020199 )
        {
            presentingViewController = parameters.presentingViewController ?: [ALUtils topViewControllerFromKeyWindow];
        }
        else
        {
            presentingViewController = [ALUtils topViewControllerFromKeyWindow];
        }
        
        [self.bidInterstitialVideoManager showFromViewController: presentingViewController];
    }
    else if ( [self.interstitialVideoManager isVideoReadyToPlayWithPlacementId: placementId unitId: unitId] )
    {
        [self log: @"Showing mediated interstitial..."];
        
        UIViewController *presentingViewController;
        if ( ALSdk.versionCode >= 11020199 )
        {
            presentingViewController = parameters.presentingViewController ?: [ALUtils topViewControllerFromKeyWindow];
        }
        else
        {
            presentingViewController = [ALUtils topViewControllerFromKeyWindow];
        }
        
        [self.interstitialVideoManager showFromViewController: presentingViewController];
    }
    else
    {
        [self log: @"Unable to show interstitial - no ad loaded..."];
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [delegate didFailToDisplayInterstitialAdWithError: [MAAdapterError errorWithCode: -4205
                                                                             errorString: @"Ad Display Failed"
                                                                  thirdPartySdkErrorCode: 0
                                                               thirdPartySdkErrorMessage: @"Interstitial ad not ready"]];
#pragma clang diagnostic pop
    }
}

#pragma mark - MAAppOpenAdapter Methods

- (void)loadAppOpenAdForParameters:(id<MAAdapterResponseParameters>)parameters andNotify:(id<MAAppOpenAdapterDelegate>)delegate
{
    NSString *unitId = parameters.thirdPartyAdPlacementIdentifier;
    NSString *placementId = [parameters.serverParameters al_stringForKey: @"placement_id"];
    
    [self log: @"Loading app open ad for unit id: %@ and placement id: %@...", unitId, placementId];
    
    self.appOpenAd = [[MTGSplashAD alloc] initWithPlacementID: placementId
                                                       unitID: unitId
                                                    countdown: 5 // Default value on Android
                                                    allowSkip: YES]; // Default value on Android
    self.appOpenAdDelegate = [[ALMintegralMediationAdapterAppOpenAdDelegate alloc] initWithParentAdapter: self andNotify: delegate];
    self.appOpenAd.delegate = self.appOpenAdDelegate;
    
    [self.appOpenAd preloadWithBidToken: parameters.bidResponse];
}

- (void)showAppOpenAdForParameters:(id<MAAdapterResponseParameters>)parameters andNotify:(id<MAAppOpenAdapterDelegate>)delegate
{
    if ( ![self.appOpenAd isBiddingADReadyToShow] )
    {
        [self log: @"Unable to show app open ad - no ad loaded..."];
        [delegate didFailToDisplayAppOpenAdWithError: [MAAdapterError errorWithCode: -4205
                                                                        errorString: @"Ad Display Failed"
                                                           mediatedNetworkErrorCode: 0
                                                        mediatedNetworkErrorMessage: @"App open ad not ready"]];
        
        return;
    }
    
    [self log: @"Showing app open ad..."];
    [self.appOpenAd showBiddingADInKeyWindow: [UIApplication sharedApplication].keyWindow customView: nil];
}

#pragma mark - MARewardedAdapter Methods

- (void)loadRewardedAdForParameters:(id<MAAdapterResponseParameters>)parameters andNotify:(id<MARewardedAdapterDelegate>)delegate
{
    // Overwritten by `mute_state` setting, unless `mute_state` is disabled
    BOOL shouldUpdateMuteState = [parameters.serverParameters al_containsValueForKey: @"is_muted"]; // Introduced in 6.10.0
    BOOL muted = [parameters.serverParameters al_numberForKey: @"is_muted"].boolValue;
    
    self.rewardedDelegate = [[ALMintegralMediationAdapterRewardedDelegate alloc] initWithParentAdapter: self andNotify: delegate];
    
    NSString *unitId = parameters.thirdPartyAdPlacementIdentifier;
    NSString *placementId = [parameters.serverParameters al_stringForKey: @"placement_id"];
    
    if ( [parameters.bidResponse al_isValidString] )
    {
        [self log: @"Loading bidding rewarded ad for unit id: %@ and placement id: %@...", unitId, placementId];
        
        if ( shouldUpdateMuteState ) [MTGBidRewardAdManager sharedInstance].playVideoMute = muted;
        
        [[MTGBidRewardAdManager sharedInstance] loadVideoWithBidToken: parameters.bidResponse
                                                          placementId: placementId
                                                               unitId: unitId
                                                             delegate: self.rewardedDelegate];
    }
    else
    {
        [self log: @"Loading mediated rewarded ad for unit id: %@ and placement id: %@...", unitId, placementId];
        
        if ( [[MTGRewardAdManager sharedInstance] isVideoReadyToPlayWithPlacementId: placementId unitId: unitId] )
        {
            [self log: @"A mediated rewarded ad is ready already"];
            [delegate didLoadRewardedAd];
        }
        else
        {
            if ( shouldUpdateMuteState ) [MTGRewardAdManager sharedInstance].playVideoMute = muted;
            
            [[MTGRewardAdManager sharedInstance] loadVideoWithPlacementId: placementId
                                                                   unitId: unitId
                                                                 delegate: self.rewardedDelegate];
        }
    }
}

- (void)showRewardedAdForParameters:(id<MAAdapterResponseParameters>)parameters andNotify:(id<MARewardedAdapterDelegate>)delegate
{
    // Configure reward from server.
    [self configureRewardForParameters: parameters];
    
    NSDictionary<NSString *, id> *serverParameters = parameters.serverParameters;
    NSString *rewardId = serverParameters[@"reward_id"];
    NSString *userId = serverParameters[@"user_id"];
    
    NSString *unitId = parameters.thirdPartyAdPlacementIdentifier;
    NSString *placementId = [serverParameters al_stringForKey: @"placement_id"];
    
    if ( [[MTGBidRewardAdManager sharedInstance] isVideoReadyToPlayWithPlacementId: placementId unitId: unitId] )
    {
        [self log: @"Showing bidding rewarded ad..."];
        
        UIViewController *presentingViewController;
        if ( ALSdk.versionCode >= 11020199 )
        {
            presentingViewController = parameters.presentingViewController ?: [ALUtils topViewControllerFromKeyWindow];
        }
        else
        {
            presentingViewController = [ALUtils topViewControllerFromKeyWindow];
        }
        
        [[MTGBidRewardAdManager sharedInstance] showVideoWithPlacementId: placementId
                                                                  unitId: unitId
                                                            withRewardId: rewardId
                                                                  userId: userId
                                                                delegate: self.rewardedDelegate
                                                          viewController: presentingViewController];
    }
    else if ( [[MTGRewardAdManager sharedInstance] isVideoReadyToPlayWithPlacementId: placementId unitId: unitId] )
    {
        [self log: @"Showing mediated rewarded ad..."];
        
        UIViewController *presentingViewController;
        if ( ALSdk.versionCode >= 11020199 )
        {
            presentingViewController = parameters.presentingViewController ?: [ALUtils topViewControllerFromKeyWindow];
        }
        else
        {
            presentingViewController = [ALUtils topViewControllerFromKeyWindow];
        }
        
        [[MTGRewardAdManager sharedInstance] showVideoWithPlacementId: placementId
                                                               unitId: unitId
                                                         withRewardId: rewardId
                                                               userId: userId
                                                             delegate: self.rewardedDelegate
                                                       viewController: presentingViewController];
    }
    else
    {
        [self log: @"Unable to show rewarded ad - no ad loaded..."];
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [delegate didFailToDisplayRewardedAdWithError: [MAAdapterError errorWithCode: -4205
                                                                         errorString: @"Ad Display Failed"
                                                              thirdPartySdkErrorCode: 0
                                                           thirdPartySdkErrorMessage: @"Rewarded ad not ready"]];
#pragma clang diagnostic pop
    }
}

#pragma mark - MAAdViewAdapter Methods

- (void)loadAdViewAdForParameters:(id<MAAdapterResponseParameters>)parameters
                         adFormat:(MAAdFormat *)adFormat
                        andNotify:(id<MAAdViewAdapterDelegate>)delegate
{
    MTGBannerSizeType sizeType = [self sizeTypeFromAdFormat: adFormat];
    
    NSString *unitId = parameters.thirdPartyAdPlacementIdentifier;
    NSString *placementId = [parameters.serverParameters al_stringForKey: @"placement_id"];
    
    BOOL isNative = [parameters.serverParameters al_boolForKey: @"is_native"];
    [self log: @"Loading%@%@ AdView ad for placement: %lld...", isNative ? @" native " : @" ", adFormat.label, placementId];
    
    if ( isNative )
    {
        self.nativeAdViewDelegate = [[ALMintegralMediationAdapterNativeAdViewDelegate alloc] initWithParentAdapter: self
                                                                                                            format: adFormat
                                                                                                        parameters: parameters
                                                                                                         andNotify: delegate];
        
        // NOTE: Mintegral's demo and MoPub's adapter does not enable `autoCacheImage` - may not guarantee that the image is cached
        self.bidNativeAdViewManager = [[MTGBidNativeAdManager alloc] initWithPlacementId: placementId
                                                                                  unitID: unitId
                                                                          autoCacheImage: NO
                                                                presentingViewController: nil];
        
        self.bidNativeAdViewManager.delegate = self.nativeAdViewDelegate;
        [self.bidNativeAdViewManager loadWithBidToken: parameters.bidResponse];
    }
    else
    {
        self.bannerAdView = [[MTGBannerAdView alloc] initBannerAdViewWithBannerSizeType: sizeType
                                                                            placementId: placementId
                                                                                 unitId: unitId
                                                                     rootViewController: [ALUtils topViewControllerFromKeyWindow]];
        
        self.bannerDelegate = [[ALMintegralMediationAdapterBannerViewDelegate alloc] initWithParentAdapter: self andNotify: delegate];
        self.bannerAdView.delegate = self.bannerDelegate;
        
        self.bannerAdView.autoRefreshTime = 0;
        self.bannerAdView.showCloseButton = MTGBoolNo;
        
        if ( [parameters.bidResponse al_isValidString] )
        {
            [self.bannerAdView loadBannerAdWithBidToken: parameters.bidResponse];
        }
        else
        {
            [self.bannerAdView loadBannerAd];
        }
    }
}

#pragma mark - MANativeAdAdapter Methods

- (void)loadNativeAdForParameters:(id<MAAdapterResponseParameters>)parameters andNotify:(id<MANativeAdAdapterDelegate>)delegate
{
    NSString *unitId = parameters.thirdPartyAdPlacementIdentifier;
    NSString *placementId = [parameters.serverParameters al_stringForKey: @"placement_id"];
    
    [self log: @"Loading bidding native ad for unit id: %@ and placement id: %@...", unitId, placementId];
    
    self.nativeAdDelegate = [[ALMintegralMediationAdapterNativeAdDelegate alloc] initWithParentAdapter: self
                                                                                            parameters: parameters
                                                                                             andNotify: delegate];
    
    // NOTE: Mintegral's demo and MoPub's adapter does not enable `autoCacheImage` - may not guarantee that the image is cached
    self.bidNativeAdManager = [[MTGBidNativeAdManager alloc] initWithPlacementId: placementId
                                                                          unitID: unitId
                                                                  autoCacheImage: NO
                                                        presentingViewController: nil];
    
    self.bidNativeAdManager.delegate = self.nativeAdDelegate;
    [self.bidNativeAdManager loadWithBidToken: parameters.bidResponse];
}

#pragma mark - Shared Methods

- (MintegralAdType)toMintegralAdType:(MAAdFormat *)adFormat
{
    if ( adFormat == MAAdFormat.interstitial )
    {
        return MintegralIntersitialAd;
    }
    else if ( adFormat == MAAdFormat.rewarded )
    {
        return MintegralRewardVideoAd;
    }
    else if ( adFormat == MAAdFormat.appOpen )
    {
        return MintegralSplashAd;
    }
    else if ( adFormat == MAAdFormat.banner || adFormat == MAAdFormat.leader || adFormat == MAAdFormat.mrec )
    {
        return MintegralBannerAd;
    }
    else if ( adFormat == MAAdFormat.native )
    {
        return MintegralNativeAd;
    }
    
    return -1;
}

+ (MAAdapterError *)toMaxError:(NSError *)mintegralError
{
    MTGErrorCode mintegralErrorCode = mintegralError.code;
    MAAdapterError *adapterError = MAAdapterError.unspecified;
    switch ( mintegralErrorCode )
    {
        case KMTGErrorCodeEmptyUnitId:
        case EXCEPTION_SIGN_ERROR:
        case EXCEPTION_UNIT_NOT_FOUND:
        case EXCEPTION_UNIT_ID_EMPTY:
        case EXCEPTION_UNIT_NOT_FOUND_IN_APP:
        case EXCEPTION_UNIT_ADTYPE_ERROR:
        case EXCEPTION_APP_ID_EMPTY:
        case EXCEPTION_APP_NOT_FOUND:
            adapterError = MAAdapterError.invalidConfiguration;
            break;
        case kMTGErrorCodeNoAds:
        case kMTGErrorCodeNoAdsAvailableToPlay:
        case EXCEPTION_RETURN_EMPTY:
            adapterError = MAAdapterError.noFill;
            break;
        case kMTGErrorCodeConnectionLost:
        case kMTGErrorCodeSocketIO:
            adapterError = MAAdapterError.noConnection;
            break;
        case kMTGErrorCodeDailyLimit:
            adapterError = MAAdapterError.adFrequencyCappedError;
            break;
        case kMTGErrorCodeLoadAdsTimeOut:
        case EXCEPTION_TIMEOUT:
            adapterError = MAAdapterError.timeout;
            break;
        case kMTGErrorCodeOfferExpired:
            adapterError = MAAdapterError.adExpiredError;
            break;
        case EXCEPTION_IV_RECALLNET_INVALIDATE:
            adapterError = MAAdapterError.notInitialized;
            break;
        case kMTGErrorCodeUnknownError:
        case kMTGErrorCodeRewardVideoFailedToLoadVideoData:
        case kMTGErrorCodeRewardVideoFailedToLoadPlayable:
        case kMTGErrorCodeRewardVideoFailedToLoadTemplateImage:
        case kMTGErrorCodeRewardVideoFailedToLoadPlayableURLFailed:
        case kMTGErrorCodeRewardVideoFailedToLoadPlayableURLReadyTimeOut:
        case kMTGErrorCodeRewardVideoFailedToLoadPlayableURLReadyNO:
        case kMTGErrorCodeRewardVideoFailedToLoadPlayableURLInvalid:
        case kMTGErrorCodeRewardVideoFailedToLoadMd5Invalid:
        case kMTGErrorCodeRewardVideoFailedToSettingInvalid:
        case KMTGErrorCodeEmptyBidToken:
        case kMTGErrorCodeURLisEmpty:
        case kMTGErrorCodeFailedToPlay:
        case kMTGErrorCodeFailedToLoad:
        case kMTGErrorCodeFailedToShow:
        case kMTGErrorCodeFailedToShowCbp:
        case kMTGErrorCodeMaterialLoadFailed:
        case kMTGErrorCodeNoSupportPopupWindow:
        case kMTGErrorCodeFailedDiskIO:
        case kMTGErrorCodeImageURLisEmpty:
            adapterError = MAAdapterError.internalError;
            break;
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [MAAdapterError errorWithCode: adapterError.errorCode
                             errorString: adapterError.errorMessage
                  thirdPartySdkErrorCode: mintegralErrorCode
               thirdPartySdkErrorMessage: mintegralError.localizedDescription];
#pragma clang diagnostic pop
}

- (void)loadImageForURLString:(NSString *)urlString group:(dispatch_group_t)group successHandler:(void (^)(UIImage *image))successHandler;
{
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        dispatch_group_enter(group);
        
        [[[NSURLSession sharedSession] dataTaskWithURL: [NSURL URLWithString: urlString]
                                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if ( error )
            {
                [self log: @"Failed to fetch native ad image with error: %@", error];
            }
            else if ( data )
            {
                [self log: @"Native ad image data retrieved"];
                
                UIImage *image = [UIImage imageWithData: data];
                if ( image )
                {
                    successHandler(image);
                }
            }
            
            // Don't consider the block done until this task is complete
            dispatch_group_leave(group);
        }] resume];
    });
}

- (MANativeAdView *)createMaxNativeAdViewWithNativeAd:(MANativeAd *)maxNativeAd templateName:(NSString *)templateName
{
    // Backend will pass down `vertical` as the template to indicate using a vertical native template
    if ( [templateName containsString: @"vertical"] )
    {
        if ( ALSdk.versionCode < 6140500 )
        {
            [self log: @"Vertical native banners are only supported on MAX SDK 6.14.5 and above. Default native template will be used."];
        }
        
        if ( [templateName isEqualToString: @"vertical"] )
        {
            NSString *verticalTemplateName = ( maxNativeAd.format == MAAdFormat.leader ) ? @"vertical_leader_template" : @"vertical_media_banner_template";
            return [MANativeAdView nativeAdViewFromAd: maxNativeAd withTemplate: verticalTemplateName];
        }
        else
        {
            return [MANativeAdView nativeAdViewFromAd: maxNativeAd withTemplate: templateName];
        }
    }
    else if ( ALSdk.versionCode < 6140500 )
    {
        return [MANativeAdView nativeAdViewFromAd: maxNativeAd withTemplate: [templateName al_isValidString] ? templateName : @"no_body_banner_template"];
    }
    else
    {
        return [MANativeAdView nativeAdViewFromAd: maxNativeAd withTemplate: [templateName al_isValidString] ? templateName : @"media_banner_template"];
    }
}

- (MTGBannerSizeType)sizeTypeFromAdFormat:(MAAdFormat *)adFormat
{
    if ( adFormat == MAAdFormat.banner || adFormat == MAAdFormat.leader )
    {
        return MTGSmartBannerType;
    }
    else if ( adFormat == MAAdFormat.mrec )
    {
        return MTGMediumRectangularBanner300x250;
    }
    else
    {
        [NSException raise: NSInvalidArgumentException format: @"Unsupported ad format: %@", adFormat];
        
        return MTGSmartBannerType;
    }
}

- (NSArray<UIView *> *)clickableViewsForNativeAdView:(MANativeAdView *)maxNativeAdView
{
    NSMutableArray *clickableViews = [NSMutableArray array];
    if ( maxNativeAdView.titleLabel )
    {
        [clickableViews addObject: maxNativeAdView.titleLabel];
    }
    if ( maxNativeAdView.advertiserLabel )
    {
        [clickableViews addObject: maxNativeAdView.advertiserLabel];
    }
    if ( maxNativeAdView.bodyLabel )
    {
        [clickableViews addObject: maxNativeAdView.bodyLabel];
    }
    if ( maxNativeAdView.callToActionButton )
    {
        [clickableViews addObject: maxNativeAdView.callToActionButton];
    }
    if ( maxNativeAdView.iconImageView )
    {
        [clickableViews addObject: maxNativeAdView.iconImageView];
    }
    
    return clickableViews;
}

@end

#pragma mark - MTGInterstitialDelegate Methods

@implementation ALMintegralMediationAdapterInterstitialDelegate

- (instancetype)initWithParentAdapter:(ALMintegralMediationAdapter *)parentAdapter andNotify:(id<MAInterstitialAdapterDelegate>)delegate
{
    self = [super init];
    if ( self )
    {
        self.parentAdapter = parentAdapter;
        self.delegate = delegate;
    }
    return self;
}

- (void)onInterstitialVideoLoadSuccess:(MTGInterstitialVideoAdManager *)adManager
{
    // Ad has loaded and video has been downloaded
    [self.parentAdapter log: @"Interstitial successfully loaded and video has been downloaded"];
    
    // Passing extra info such as creative id supported in 6.15.0+
    NSString *requestId = [adManager getRequestIdWithUnitId: adManager.currentUnitId];
    if ( ALSdk.versionCode >= 6150000 && [requestId al_isValidString] )
    {
        [self.delegate performSelector: @selector(didLoadInterstitialAdWithExtraInfo:)
                            withObject: @{@"creative_id" : requestId}];
    }
    else
    {
        [self.delegate didLoadInterstitialAd];
    }
}

- (void)onInterstitialAdLoadSuccess:(MTGInterstitialVideoAdManager *)adManager
{
    // Ad has loaded but video still needs to be downloaded
    [self.parentAdapter log: @"Interstitial successfully loaded but video still needs to be downloaded"];
}

- (void)onInterstitialVideoLoadFail:(NSError *)error adManager:(MTGInterstitialVideoAdManager *)adManager
{
    [self.parentAdapter log: @"Interstitial failed to load: %@", error];
    
    MAAdapterError *adapterError = [ALMintegralMediationAdapter toMaxError: error];
    [self.delegate didFailToLoadInterstitialAdWithError: adapterError];
}

- (void)onInterstitialVideoShowSuccess:(MTGInterstitialVideoAdManager *)adManager
{
    [self.parentAdapter log: @"Interstitial displayed"];
    [self.delegate didDisplayInterstitialAd];
}

- (void)onInterstitialVideoShowFail:(NSError *)error adManager:(MTGInterstitialVideoAdManager *)adManager
{
    [self.parentAdapter log: @"Interstitial failed to show: %@", error];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    MAAdapterError *adapterError = [MAAdapterError errorWithCode: -4205
                                                     errorString: @"Ad Display Failed"
                                          thirdPartySdkErrorCode: error.code
                                       thirdPartySdkErrorMessage: error.localizedDescription];
#pragma clang diagnostic pop
    [self.delegate didFailToDisplayInterstitialAdWithError: adapterError];
}

- (void)onInterstitialVideoAdClick:(MTGInterstitialVideoAdManager *)adManager
{
    [self.parentAdapter log: @"Interstitial clicked"];
    [self.delegate didClickInterstitialAd];
}

- (void)onInterstitialVideoAdDismissedWithConverted:(BOOL)converted adManager:(MTGInterstitialVideoAdManager *)adManager
{
    [self.parentAdapter log: @"Interstitial hidden"];
    [self.delegate didHideInterstitialAd];
}

- (void)onInterstitialVideoAdDidClosed:(MTGInterstitialVideoAdManager *)adManager
{
    [self.parentAdapter log: @"Interstitial video completed"];
}

- (void)onInterstitialVideoEndCardShowSuccess:(MTGInterstitialVideoAdManager *)adManager
{
    [self.parentAdapter log: @"Interstitial endcard shown"];
}

@end

@implementation ALMintegralMediationAdapterAppOpenAdDelegate

- (instancetype)initWithParentAdapter:(ALMintegralMediationAdapter *)parentAdapter andNotify:(id<MAAppOpenAdapterDelegate>)delegate
{
    self = [super init];
    if ( self )
    {
        self.parentAdapter = parentAdapter;
        self.delegate = delegate;
    }
    return self;
}

- (void)splashADPreloadSuccess:(MTGSplashAD *)splashAD
{
    [self.parentAdapter log: @"App open ad loaded"];
    
    NSDictionary *extraInfo;
    if ( [splashAD.requestID al_isValidString] )
    {
        extraInfo = @{@"creative_id" : splashAD.requestID};
    }
    
    [self.delegate didLoadAppOpenAdWithExtraInfo: extraInfo];
}

- (void)splashADPreloadFail:(MTGSplashAD *)splashAD error:(NSError *)error
{
    MAAdapterError *adapterError = [ALMintegralMediationAdapter toMaxError: error];
    [self.parentAdapter log: @"App open ad failed to load: %@", adapterError];
    [self.delegate didFailToLoadAppOpenAdWithError: adapterError];
}

- (void)splashADShowSuccess:(MTGSplashAD *)splashAD
{
    [self.parentAdapter log: @"App open ad displayed"];
    [self.delegate didDisplayAppOpenAd];
}

- (void)splashADShowFail:(MTGSplashAD *)splashAD error:(NSError *)error
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    MAAdapterError *adapterError = [MAAdapterError errorWithCode: -4205
                                                     errorString: @"Ad Display Failed"
                                          thirdPartySdkErrorCode: error.code
                                       thirdPartySdkErrorMessage: error.localizedDescription];
#pragma clang diagnostic pop
    
    [self.parentAdapter log: @"App open ad failed to show: %@", adapterError];
    [self.delegate didFailToDisplayAppOpenAdWithError: adapterError];
}

- (void)splashADDidClick:(MTGSplashAD *)splashAD
{
    [self.parentAdapter log: @"App open ad clicked"];
    [self.delegate didClickAppOpenAd];
}

- (void)splashADDidLeaveApplication:(MTGSplashAD *)splashAD
{
    [self.parentAdapter log: @"App open ad left application"];
}

- (void)splashADWillClose:(MTGSplashAD *)splashAD
{
    [self.parentAdapter log: @"App open ad will hide"];
}

- (void)splashADDidClose:(MTGSplashAD *)splashAD
{
    [self.parentAdapter log: @"App open ad hidden"];
    [self.delegate didHideAppOpenAd];
}

//
// Un-used callbacks, but `MTGSplashADDelegate` declared all callbacks as non-optional
//

- (void)splashADLoadSuccess:(MTGSplashAD *)splashAD {}

- (void)splashADLoadFail:(MTGSplashAD *)splashAD error:(NSError *)error {}

- (CGPoint)pointForSplashZoomOutADViewToAddOn:(MTGSplashAD *)splashAD { return CGPointZero; }

- (void)splashAD:(MTGSplashAD *)splashAD timeLeft:(NSUInteger)time {}

- (void)splashZoomOutADViewClosed:(MTGSplashAD *)splashAD {}

- (void)splashZoomOutADViewDidShow:(MTGSplashAD *)splashAD {}

- (UIView *)superViewForSplashZoomOutADViewToAddOn:(MTGSplashAD *)splashAD { return [UIApplication sharedApplication].keyWindow; }

@end

#pragma mark - MTGRewardedDelegate Methods

@implementation ALMintegralMediationAdapterRewardedDelegate

- (instancetype)initWithParentAdapter:(ALMintegralMediationAdapter *)parentAdapter andNotify:(id<MARewardedAdapterDelegate>)delegate
{
    self = [super init];
    if ( self )
    {
        self.parentAdapter = parentAdapter;
        self.delegate = delegate;
    }
    return self;
}

- (void)onVideoAdLoadSuccess:(nullable NSString *)placementId unitId:(nullable NSString *)unitId
{
    // Ad has loaded and video has been downloaded
    [self.parentAdapter log: @"Rewarded ad successfully loaded and video has been downloaded"];
    
    // Attempt to get request/creative id from bid manager first
    NSString *requestId = [[MTGBidRewardAdManager sharedInstance] getRequestIdWithUnitId: unitId];
    if ( ![requestId al_isValidString] ) // ... then placement manager if not found from bid manager
    {
        requestId = [[MTGRewardAdManager sharedInstance] getRequestIdWithUnitId: unitId];
    }
    
    // Passing extra info such as creative id supported in 6.15.0+
    if ( ALSdk.versionCode >= 6150000 && [requestId al_isValidString] )
    {
        [self.delegate performSelector: @selector(didLoadRewardedAdWithExtraInfo:)
                            withObject: @{@"creative_id" : requestId}];
    }
    else
    {
        [self.delegate didLoadRewardedAd];
    }
}

- (void)onAdLoadSuccess:(nullable NSString *)placementId unitId:(nullable NSString *)unitId
{
    // Ad has loaded but video still needs to be downloaded
    [self.parentAdapter log: @"Rewarded ad successfully loaded but video still needs to be downloaded"];
}

- (void)onVideoAdLoadFailed:(nullable NSString *)placementId unitId:(nullable NSString *)unitId error:(NSError *)error
{
    [self.parentAdapter log: @"Rewarded ad failed to load: %@", error];
    
    MAAdapterError *adapterError = [ALMintegralMediationAdapter toMaxError: error];
    [self.delegate didFailToLoadRewardedAdWithError: adapterError];
}

- (void)onVideoAdShowSuccess:(nullable NSString *)placementId unitId:(nullable NSString *)unitId
{
    [self.parentAdapter log: @"Rewarded ad displayed"];
    [self.delegate didDisplayRewardedAd];
    [self.delegate didStartRewardedAdVideo];
}

- (void)onVideoAdShowFailed:(nullable NSString *)placementId unitId:(nullable NSString *)unitId withError:(NSError *)error
{
    [self.parentAdapter log: @"Rewarded ad failed to show: %@", error];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    MAAdapterError *adapterError = [MAAdapterError errorWithCode: -4205
                                                     errorString: @"Ad Display Failed"
                                          thirdPartySdkErrorCode: error.code
                                       thirdPartySdkErrorMessage: error.localizedDescription];
#pragma clang diagnostic pop
    [self.delegate didFailToDisplayRewardedAdWithError: adapterError];
}

- (void)onVideoAdClicked:(nullable NSString *)placementId unitId:(nullable NSString *)unitId
{
    [self.parentAdapter log: @"Rewarded ad clicked"];
    [self.delegate didClickRewardedAd];
}

- (void)onVideoAdDismissed:(nullable NSString *)placementId unitId:(nullable NSString *)unitId withConverted:(BOOL)converted withRewardInfo:(nullable MTGRewardAdInfo *)rewardInfo
{
    [self.parentAdapter log: @"Rewarded ad granted reward"];
    self.grantedReward = converted;
}

- (void)onVideoAdDidClosed:(nullable NSString *)placementId unitId:(nullable NSString *)unitId
{
    [self.parentAdapter log: @"Rewarded ad hidden"];
    
    [self.delegate didCompleteRewardedAdVideo];
    
    if ( [self hasGrantedReward] || [self.parentAdapter shouldAlwaysRewardUser] )
    {
        MAReward *reward = [self.parentAdapter reward];
        [self.parentAdapter log: @"Rewarded user with reward: %@", reward];
        [self.delegate didRewardUserWithReward: reward];
    }
    
    [self.delegate didHideRewardedAd];
}

- (void)onVideoPlayCompleted:(nullable NSString *)placementId unitId:(nullable NSString *)unitId
{
    [self.parentAdapter log: @"Rewarded ad video completed"];
}

- (void)onVideoEndCardShowSuccess:(nullable NSString *)placementId unitId:(nullable NSString *)unitId
{
    [self.parentAdapter log: @"Rewarded ad endcard shown"];
}

@end

#pragma mark MTGAdViewDelegate Methods

@implementation  ALMintegralMediationAdapterBannerViewDelegate

- (instancetype)initWithParentAdapter:(ALMintegralMediationAdapter *)parentAdapter andNotify:(id<MAAdViewAdapterDelegate>)delegate
{
    self = [super init];
    if ( self )
    {
        self.parentAdapter = parentAdapter;
        self.delegate = delegate;
    }
    return self;
}

- (void)adViewLoadSuccess:(MTGBannerAdView *)adView
{
    [self.parentAdapter log: @"Banner ad loaded"];
    
    // Passing extra info such as creative id supported in 6.15.0+
    if ( ALSdk.versionCode >= 6150000 && [adView.requestId al_isValidString] )
    {
        [self.delegate performSelector: @selector(didLoadAdForAdView:withExtraInfo:)
                            withObject: adView
                            withObject: @{@"creative_id" : adView.requestId}];
    }
    else
    {
        [self.delegate didLoadAdForAdView: adView];
    }
}

- (void)adViewLoadFailedWithError:(NSError *)error adView:(MTGBannerAdView *)adView
{
    [self.parentAdapter log: @"Banner ad failed to load: %@", error];
    
    MAAdapterError *adapterError = [ALMintegralMediationAdapter toMaxError: error];
    [self.delegate didFailToLoadAdViewAdWithError: adapterError];
}

- (void)adViewWillLogImpression:(MTGBannerAdView *)adView
{
    [self.parentAdapter log: @"Banner ad displayed"];
    [self.delegate didDisplayAdViewAd];
}

- (void)adViewDidClicked:(MTGBannerAdView *)adView
{
    [self.parentAdapter log: @"Banner ad clicked"];
    [self.delegate didClickAdViewAd];
}

- (void)adViewWillLeaveApplication:(MTGBannerAdView *)adView
{
    [self.parentAdapter log: @"Banner ad will leave application"];
}

- (void)adViewWillOpenFullScreen:(MTGBannerAdView *)adView
{
    [self.parentAdapter log: @"Banner ad expanded"];
    [self.delegate didExpandAdViewAd];
}

- (void)adViewCloseFullScreen:(MTGBannerAdView *)adView
{
    [self.parentAdapter log: @"Banner ad collapsed"];
    [self.delegate didCollapseAdViewAd];
}

- (void)adViewClosed:(MTGBannerAdView *)adView
{
    [self.parentAdapter log: @"Banner ad closed"];
    [self.delegate didHideAdViewAd];
}

@end

#pragma mark MTGNativeAdViewDelegate Methods

@implementation ALMintegralMediationAdapterNativeAdViewDelegate

- (instancetype)initWithParentAdapter:(ALMintegralMediationAdapter *)parentAdapter format:(MAAdFormat *)format parameters:(id<MAAdapterResponseParameters>)parameters andNotify:(id<MAAdViewAdapterDelegate>)delegate
{
    self = [super init];
    if ( self )
    {
        self.parentAdapter = parentAdapter;
        self.format = format;
        self.serverParameters = parameters.serverParameters;
        self.delegate = delegate;
        
        self.unitId = parameters.thirdPartyAdPlacementIdentifier;
        self.placementId = [self.serverParameters al_stringForKey: @"placement_id"];
    }
    return self;
}

- (void)nativeAdsLoaded:(NSArray *)nativeAds bidNativeManager:(MTGBidNativeAdManager *)bidNativeManager
{
    if ( !nativeAds || nativeAds.count == 0 )
    {
        [self.parentAdapter log: @"Native %@ ad failed to load for unit id: %@ placement id: %@ with error: no fill", self.format.label, self.unitId, self.placementId];
        [self.delegate didFailToLoadAdViewAdWithError: MAAdapterError.noFill];
        return;
    }
    
    MTGCampaign *campaign = nativeAds[0];
    if ( ![campaign.appName al_isValidString] )
    {
        [self.parentAdapter log: @"Native %@ ad failed to load for unit id: %@ placement id: %@ with error: missing required assets", self.format.label, self.unitId, self.placementId];
        [self.delegate didFailToLoadAdViewAdWithError: [MAAdapterError errorWithCode: -5400 errorString: @"Missing Native Ad Assets"]];
        
        return;
    }
    
    self.parentAdapter.nativeAdCampaign = campaign;
    
    [self.parentAdapter log: @"Native %@ ad loaded for unit id: %@ placement id: %@", self.format.label, self.unitId, self.placementId];
    
    // Run image fetching tasks asynchronously in the background
    dispatch_group_t group = dispatch_group_create();
    
    __block MANativeAdImage *iconImage = nil;
    __block MANativeAdImage *mainImage = nil;
    NSString *iconURL = campaign.iconUrl;
    NSString *mainImageURL = campaign.imageUrl;
    if ( [iconURL al_isValidURL] )
    {
        [self.parentAdapter log: @"Fetching native ad icon: %@", iconURL];
        [self.parentAdapter loadImageForURLString: iconURL group: group successHandler:^(UIImage *image) {
            iconImage = [[MANativeAdImage alloc] initWithImage: image];
        }];
    }
    if ( [mainImageURL al_isValidString] )
    {
        [self.parentAdapter log: @"Fetching native ad main image: %@", mainImageURL];
        [self.parentAdapter loadImageForURLString: mainImageURL group: group successHandler:^(UIImage *image) {
            mainImage = [[MANativeAdImage alloc] initWithImage: image];
        }];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // Timeout tasks if incomplete within the given time
        NSTimeInterval imageTaskTimeoutSeconds = [[self.serverParameters al_numberForKey: @"image_task_timeout_seconds" defaultValue: @(kDefaultImageTaskTimeoutSeconds)] doubleValue];
        dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, (int64_t) (imageTaskTimeoutSeconds * NSEC_PER_SEC)));
        
        dispatchOnMainQueue(^{
            MTGMediaView *mediaView = [[MTGMediaView alloc] initWithFrame: CGRectZero];
            [mediaView setMediaSourceWithCampaign: campaign unitId: self.unitId];
            mediaView.delegate = self;
            
            MTGAdChoicesView *adChoicesView = [[MTGAdChoicesView alloc] initWithFrame: CGRectZero];
            adChoicesView.campaign = campaign;
            
            MANativeAd *maxNativeAdViewAd = [[MAMintegralNativeAd alloc] initWithParentAdapter: self.parentAdapter adFormat: self.format builderBlock:^(MANativeAdBuilder *builder) {
                builder.title = campaign.appName;
                builder.body = campaign.appDesc;
                builder.callToAction = campaign.adCall;
                builder.icon = iconImage;
                builder.mediaView = mediaView;
                builder.optionsView = adChoicesView;
            }];
            
            NSString *templateName = [self.serverParameters al_stringForKey: @"template" defaultValue: @""];
            MANativeAdView *maxNativeAdView = [self.parentAdapter createMaxNativeAdViewWithNativeAd: maxNativeAdViewAd templateName: templateName];
            
            [maxNativeAdViewAd prepareForInteractionClickableViews: [self.parentAdapter clickableViewsForNativeAdView: maxNativeAdView] withContainer: maxNativeAdView];
            
            // Mintegral is not providing creative id for native ads
            [self.delegate didLoadAdForAdView: maxNativeAdView];
        });
    });
}

- (void)nativeAdsFailedToLoadWithError:(NSError *)error bidNativeManager:(MTGBidNativeAdManager *)bidNativeManager
{
    MAAdapterError *adapterError = [ALMintegralMediationAdapter toMaxError: error];
    [self.parentAdapter log: @"Native %@ ad failed to load for unit id: %@ placement id: %@ with error: %@", self.format.label, self.unitId, self.placementId, adapterError];
    [self.delegate didFailToLoadAdViewAdWithError: adapterError];
}

- (void)nativeAdImpressionWithType:(MTGAdSourceType)type bidNativeManager:(MTGBidNativeAdManager *)bidNativeManager
{
    [self.parentAdapter log: @"Native %@ ad shown for unit id: %@ placement id: %@", self.format.label, self.unitId, self.placementId];
    [self.delegate didDisplayAdViewAd];
}

- (void)nativeAdDidClick:(MTGCampaign *)nativeAd bidNativeManager:(MTGBidNativeAdManager *)bidNativeManager
{
    [self.parentAdapter log: @"Native %@ ad clicked for unit id: %@ placement id: %@", self.format.label, self.unitId, self.placementId];
    [self.delegate didClickAdViewAd];
}

- (void)nativeAdClickUrlWillStartToJump:(NSURL *)clickUrl bidNativeManager:(MTGBidNativeAdManager *)bidNativeManager
{
    [self.parentAdapter log: @"Native %@ ad click will start jump for unit id: %@ placement id: %@", self.format.label, self.unitId, self.placementId];
}

- (void)nativeAdClickUrlDidJumpToUrl:(NSURL *)jumpUrl bidNativeManager:(MTGBidNativeAdManager *)bidNativeManager
{
    [self.parentAdapter log: @"Native %@ ad click did jump for unit id: %@ placement id: %@", self.format.label, self.unitId, self.placementId];
}

- (void)nativeAdClickUrlDidEndJump:(NSURL *)finalUrl error:(NSError *)error bidNativeManager:(MTGBidNativeAdManager *)bidNativeManager
{
    [self.parentAdapter log: @"Native %@ ad click did end jump for unit id: %@ placement id: %@", self.format.label, self.unitId, self.placementId];
}

#pragma mark MTGMediaViewDelegate methods

- (void)MTGMediaViewWillEnterFullscreen:(MTGMediaView *)mediaView
{
    [self.parentAdapter log: @"Media view will enter fullscreen"];
}

- (void)MTGMediaViewDidExitFullscreen:(MTGMediaView *)mediaView
{
    [self.parentAdapter log: @"Media view did exit fullscreen"];
}

- (void)MTGMediaViewVideoDidStart:(MTGMediaView *)mediaView
{
    [self.parentAdapter log: @"Media view video did start"];
}

- (void)MTGMediaViewVideoPlayCompleted:(MTGMediaView *)mediaView
{
    [self.parentAdapter log: @"Media view video did complete"];
}

- (void)nativeAdDidClick:(MTGCampaign *)nativeAd mediaView:(MTGMediaView *)mediaView
{
    [self.parentAdapter log: @"Media view clicked for unit id: %@ placement id: %@", self.unitId, self.placementId];
    [self.delegate didClickAdViewAd];
}

- (void)nativeAdClickUrlWillStartToJump:(NSURL *)clickURL mediaView:(MTGMediaView *)mediaView
{
    [self.parentAdapter log: @"Media view click will start jump to: %@", clickURL];
}

- (void)nativeAdClickUrlDidJumpToUrl:(NSURL *)jumpURL mediaView:(MTGMediaView *)mediaView
{
    [self.parentAdapter log: @"Media view click did jump to: %@", jumpURL];
}

- (void)nativeAdClickUrlDidEndJump:(nullable NSURL *)finalURL error:(nullable NSError *)error mediaView:(MTGMediaView *)mediaView
{
    NSString *errorString = [NSString stringWithFormat: @" with error: %@", error.localizedDescription];
    [self.parentAdapter log: @"Media view click did end jump to: %@%@", finalURL, error ? errorString : @""];
}

- (void)nativeAdImpressionWithType:(MTGAdSourceType)type mediaView:(MTGMediaView *)mediaView;
{
    [self.parentAdapter log: @"Media view impression did start"];
    [self.delegate didDisplayAdViewAd];
}

@end

#pragma mark MTGNativeAdDelegate Methods

@implementation ALMintegralMediationAdapterNativeAdDelegate

- (instancetype)initWithParentAdapter:(ALMintegralMediationAdapter *)parentAdapter parameters:(id<MAAdapterResponseParameters>)parameters andNotify:(id<MANativeAdAdapterDelegate>)delegate
{
    self = [super init];
    if ( self )
    {
        self.parentAdapter = parentAdapter;
        self.serverParameters = parameters.serverParameters;
        self.delegate = delegate;
        
        self.unitId = parameters.thirdPartyAdPlacementIdentifier;
        self.placementId = [self.serverParameters al_stringForKey: @"placement_id"];
    }
    return self;
}

- (void)nativeAdsLoaded:(NSArray *)nativeAds bidNativeManager:(MTGBidNativeAdManager *)bidNativeManager
{
    if ( nativeAds.count == 0 )
    {
        [self.parentAdapter log: @"Native ad failed to load for unit id: %@ placement id: %@ with error: no fill", self.unitId, self.placementId];
        [self.delegate didFailToLoadNativeAdWithError: MAAdapterError.noFill];
        return;
    }
    
    MTGCampaign *campaign = nativeAds[0];
    
    NSString *templateName = [self.serverParameters al_stringForKey: @"template"];
    BOOL isTemplateAd = [templateName al_isValidString];
    if ( isTemplateAd && ![campaign.appName al_isValidString] )
    {
        [self.parentAdapter log: @"Native ad failed to load for unit id: %@ placement id: %@ with error: missing required assets", self.unitId, self.placementId];
        [self.delegate didFailToLoadNativeAdWithError: [MAAdapterError errorWithCode: -5400 errorString: @"Missing Native Ad Assets"]];
        
        return;
    }
    
    self.parentAdapter.nativeAdCampaign = campaign;
    
    [self.parentAdapter log: @"Native ad loaded for unit id: %@ placement id: %@", self.unitId, self.placementId];
    [self processNativeAd: campaign unitId: self.unitId];
}

- (void)nativeAdsFailedToLoadWithError:(NSError *)error bidNativeManager:(MTGBidNativeAdManager *)bidNativeManager
{
    MAAdapterError *adapterError = [ALMintegralMediationAdapter toMaxError: error];
    [self.parentAdapter log: @"Native ad failed to load for unit id: %@ placement id: %@ with error: %@", self.unitId, self.placementId, adapterError];
    [self.delegate didFailToLoadNativeAdWithError: adapterError];
}

- (void)nativeAdImpressionWithType:(MTGAdSourceType)type bidNativeManager:(MTGBidNativeAdManager *)bidNativeManager
{
    [self.parentAdapter log: @"Native ad shown for unit id: %@ placement id: %@", self.unitId, self.placementId];
    [self.delegate didDisplayNativeAdWithExtraInfo: nil];
}

- (void)nativeAdDidClick:(MTGCampaign *)nativeAd bidNativeManager:(MTGBidNativeAdManager *)bidNativeManager
{
    [self.parentAdapter log: @"Native ad clicked for unit id: %@ placement id: %@", self.unitId, self.placementId];
    [self.delegate didClickNativeAd];
}

- (void)nativeAdClickUrlWillStartToJump:(NSURL *)clickUrl bidNativeManager:(MTGBidNativeAdManager *)bidNativeManager
{
    [self.parentAdapter log: @"Native ad click will start jump for unit id: %@ placement id: %@", self.unitId, self.placementId];
}

- (void)nativeAdClickUrlDidJumpToUrl:(NSURL *)jumpUrl bidNativeManager:(MTGBidNativeAdManager *)bidNativeManager
{
    [self.parentAdapter log: @"Native ad click did jump for unit id: %@ placement id: %@", self.unitId, self.placementId];
}

- (void)nativeAdClickUrlDidEndJump:(NSURL *)finalUrl error:(NSError *)error bidNativeManager:(MTGBidNativeAdManager *)bidNativeManager
{
    [self.parentAdapter log: @"Native ad click did end jump for unit id: %@ placement id: %@", self.unitId, self.placementId];
}

- (void)processNativeAd:(MTGCampaign *)campaign unitId:(NSString *)unitId
{
    // Run image fetching tasks asynchronously in the background
    dispatch_group_t group = dispatch_group_create();
    
    __block MANativeAdImage *iconImage = nil;
    __block MANativeAdImage *mainImage = nil;
    NSString *iconURL = campaign.iconUrl;
    NSString *mainImageURL = campaign.imageUrl;
    if ( [iconURL al_isValidURL] )
    {
        [self.parentAdapter log: @"Fetching native ad icon: %@", iconURL];
        [self.parentAdapter loadImageForURLString: iconURL group: group successHandler:^(UIImage *image) {
            iconImage = [[MANativeAdImage alloc] initWithImage: image];
        }];
    }
    if ( [mainImageURL al_isValidString] )
    {
        [self.parentAdapter log: @"Fetching native ad main image: %@", mainImageURL];
        [self.parentAdapter loadImageForURLString: mainImageURL group: group successHandler:^(UIImage *image) {
            mainImage = [[MANativeAdImage alloc] initWithImage: image];
        }];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // Timeout tasks if incomplete within the given time
        NSTimeInterval imageTaskTimeoutSeconds = [[self.serverParameters al_numberForKey: @"image_task_timeout_seconds" defaultValue: @(kDefaultImageTaskTimeoutSeconds)] doubleValue];
        dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, (int64_t) (imageTaskTimeoutSeconds * NSEC_PER_SEC)));
        
        dispatchOnMainQueue(^{
            MTGMediaView *mediaView = [[MTGMediaView alloc] initWithFrame: CGRectZero];
            [mediaView setMediaSourceWithCampaign: campaign unitId: unitId];
            mediaView.delegate = self;
            
            MTGAdChoicesView *adChoicesView = [[MTGAdChoicesView alloc] initWithFrame: CGRectZero];
            adChoicesView.campaign = campaign;
            
            MANativeAd *maxNativeAd = [[MAMintegralNativeAd alloc] initWithParentAdapter: self.parentAdapter adFormat: MAAdFormat.native builderBlock:^(MANativeAdBuilder *builder) {
                builder.title = campaign.appName;
                builder.body = campaign.appDesc;
                builder.callToAction = campaign.adCall;
                builder.icon = iconImage;
                if ( ALSdk.versionCode >= 11040299 )
                {
                    [builder performSelector: @selector(setMainImage:) withObject: mainImage];
                }
                builder.mediaView = mediaView;
                builder.optionsView = adChoicesView;
            }];
            
            // To compile SOURCE code with < 11.0.0 before SDK is merged so we can push adapter
            if ( [self.delegate respondsToSelector: @selector(didLoadAdForNativeAd:withExtraInfo:)] )
            {
                [self.delegate performSelector: @selector(didLoadAdForNativeAd:withExtraInfo:)
                                    withObject: maxNativeAd
                                    withObject: @{}];
            }
        });
    });
}

#pragma mark MTGMediaViewDelegate methods

- (void)MTGMediaViewWillEnterFullscreen:(MTGMediaView *)mediaView
{
    [self.parentAdapter log: @"Media view will enter fullscreen"];
}

- (void)MTGMediaViewDidExitFullscreen:(MTGMediaView *)mediaView
{
    [self.parentAdapter log: @"Media view did exit fullscreen"];
}

- (void)MTGMediaViewVideoDidStart:(MTGMediaView *)mediaView
{
    [self.parentAdapter log: @"Media view video did start"];
}

- (void)MTGMediaViewVideoPlayCompleted:(MTGMediaView *)mediaView
{
    [self.parentAdapter log: @"Media view video did complete"];
}

- (void)nativeAdDidClick:(MTGCampaign *)nativeAd mediaView:(MTGMediaView *)mediaView
{
    [self.parentAdapter log: @"Media view clicked for unit id: %@ placement id: %@", self.unitId, self.placementId];
    [self.delegate didClickNativeAd];
}

- (void)nativeAdClickUrlWillStartToJump:(NSURL *)clickURL mediaView:(MTGMediaView *)mediaView
{
    [self.parentAdapter log: @"Media view click will start jump to: %@", clickURL];
}

- (void)nativeAdClickUrlDidJumpToUrl:(NSURL *)jumpURL mediaView:(MTGMediaView *)mediaView
{
    [self.parentAdapter log: @"Media view click did jump to: %@", jumpURL];
}

- (void)nativeAdClickUrlDidEndJump:(nullable NSURL *)finalURL error:(nullable NSError *)error mediaView:(MTGMediaView *)mediaView
{
    NSString *errorString = [NSString stringWithFormat: @" with error: %@", error.localizedDescription];
    [self.parentAdapter log: @"Media view click did end jump to: %@%@", finalURL, error ? errorString : @""];
}

- (void)nativeAdImpressionWithType:(MTGAdSourceType)type mediaView:(MTGMediaView *)mediaView;
{
    [self.parentAdapter log: @"Media view impression did start"];
    [self.delegate didDisplayNativeAdWithExtraInfo: nil];
}

@end

@implementation MAMintegralNativeAd

- (instancetype)initWithParentAdapter:(ALMintegralMediationAdapter *)parentAdapter adFormat:(MAAdFormat *)format builderBlock:(NS_NOESCAPE MANativeAdBuilderBlock)builderBlock
{
    self = [super initWithFormat: format builderBlock: builderBlock];
    if ( self )
    {
        self.parentAdapter = parentAdapter;
    }
    return self;
}

- (void)prepareViewForInteraction:(MANativeAdView *)maxNativeAdView
{
    [self prepareForInteractionClickableViews: [self.parentAdapter clickableViewsForNativeAdView: maxNativeAdView] withContainer: maxNativeAdView];
}

- (BOOL)prepareForInteractionClickableViews:(NSArray<UIView *> *)clickableViews withContainer:(UIView *)container
{
    if ( self.format == MAAdFormat.native )
    {
        [self.parentAdapter.bidNativeAdManager registerViewForInteraction: container
                                                       withClickableViews: clickableViews
                                                             withCampaign: self.parentAdapter.nativeAdCampaign];
    }
    else
    {
        [self.parentAdapter.bidNativeAdViewManager registerViewForInteraction: container
                                                           withClickableViews: clickableViews
                                                                 withCampaign: self.parentAdapter.nativeAdCampaign];
    }
    
    [self.parentAdapter d: @"Preparing views for interaction: %@ with container: %@", clickableViews, container];
    
    self.parentAdapter.maxNativeAdContainer = container;
    self.parentAdapter.clickableViews = clickableViews;
    
    return YES;
}

@end
