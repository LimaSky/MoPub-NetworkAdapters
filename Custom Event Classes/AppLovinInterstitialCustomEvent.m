/***
 *
 *  The MIT License(MIT)
 *
 *  Copyright (c) 2013 Lima Sky
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in
 *  all copies of the substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *  THE SOFTWARE.
 *
 ***/

#import "AppLovinInterstitialCustomEvent.h"
#import "MPLogging.h"

void InitializeAppLovinSDKIfNeeded()
{
    static BOOL isInitialized = NO;
    if(!isInitialized) {
        [ALSdk initializeSdk];
        isInitialized = YES;
    }
}

@implementation AppLovinInterstitialCustomEvent

- (void)requestInterstitialWithCustomEventInfo:(NSDictionary *)info
{
    MPLogInfo(@"Requesting AppLovin interstitial...");
    
    InitializeAppLovinSDKIfNeeded();
    
    ALAdService * adService = [[ALSdk shared] adService];
    [adService loadNextAd: [ALAdSize sizeInterstitial]
                 placedAt: nil
                andNotify: self];
}

- (void)showInterstitialFromRootViewController:(UIViewController *)rootViewController
{
    if (_loadedAd)
    {
        UIWindow * window = rootViewController.view.window;
        UIInterfaceOrientation currentOrientation = [[UIDevice currentDevice] orientation];
        
        CGRect localFrame;
        
        if(UIDeviceOrientationIsPortrait(currentOrientation))
        {
            localFrame = CGRectMake(0, 0, window.frame.size.width, window.frame.size.height - [UIApplication sharedApplication].statusBarFrame.size.height);
        }
        else
        {
            localFrame = CGRectMake(0, 0, window.frame.size.width - [UIApplication sharedApplication].statusBarFrame.size.width, window.frame.size.height);
        }
        
        _interstitialAd = [[ALInterstitialAd alloc] initWithFrame:localFrame];
        _interstitialAd.adDisplayDelegate = self;
        
        [self.delegate interstitialCustomEventWillAppear:self];
        
        [_interstitialAd showOver:window andRender:_loadedAd];
    }
    else
    {
        MPLogInfo(@"Failed to show AppLovin interstitial: no ad loaded");
        
        [self.delegate interstitialCustomEvent:self didFailToLoadAdWithError:nil];
    }
}

#pragma mark -
#pragma mark ALAdLoadDelegate methods
-(void)adService:(ALAdService *)adService didLoadAd:(ALAd *)ad
{
    MPLogInfo(@"Successfully loaded AppLovin interstitial.");
    
    // Release existing ad
    [_loadedAd release];
    
    // Save the newly loaded ad
    _loadedAd = ad;
    [_loadedAd retain];
    
    [self.delegate interstitialCustomEvent:self didLoadAd:ad];
}

-(void)adService:(ALAdService *)adService didFailToLoadAdWithError:(int)code
{
    MPLogInfo(@"Failed to load AppLovin interstitial: %i", code);
    
    [self.delegate interstitialCustomEvent:self didFailToLoadAdWithError:nil];
}


#pragma mark ALAdDisplayDelegate methods
-(void)ad:(ALAd *)ad wasHiddenIn:(UIView *)view
{
    MPLogInfo(@"AppLovin interstitial was dismissed");
    
    [self.delegate interstitialCustomEventWillDisappear:self];
    [self.delegate interstitialCustomEventDidDisappear:self];
}


-(void)ad:(ALAd *)ad wasDisplayedIn:(UIView *)view
{
    MPLogInfo(@"AppLovin interstitial was displayed");
    
    [self.delegate interstitialCustomEventDidAppear:self];
}

-(void)ad:(ALAd *)ad wasClickedIn:(UIView *)view
{
    MPLogInfo(@"AppLovin interstitial was clicked");
    
    [self.delegate interstitialCustomEventDidReceiveTapEvent:self];
}

- (void)dealloc
{
    _interstitialAd.adDisplayDelegate = nil;
    _interstitialAd.adLoadDelegate = nil;
    
    [_interstitialAd release];
    [_loadedAd release];
    
	[super dealloc];
}

@end
