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
 
#import "VungleInterstitialCustomEvent.h"
#import "MPInstanceProvider.h"
#import "MPLogging.h"

// This is a sample Vungle app ID. You will need to replace it with your Vungle app ID.
#define kVungleAppID @"YOUR_APP_ID_HERE"

static BOOL isVungleRunning = NO;

@interface VungleInterstitialCustomEvent ()
@end

@implementation VungleInterstitialCustomEvent

#pragma mark - MPInterstitialCustomEvent Subclass Methods

- (void)requestInterstitialWithCustomEventInfo:(NSDictionary *)info
{
    MPLogInfo(@"Requesting Vungle video interstitial");
    
    if(!isVungleRunning)
    {
        NSString *appId = [info objectForKey:@"appId"];
        if(appId == nil)
        {
            appId = kVungleAppID;
        }
        [[VungleSDK sharedSDK] startWithAppId:appId];
        
        isVungleRunning = YES;
    }
    
    [[VungleSDK sharedSDK] setDelegate:self];
    
    if([[VungleSDK sharedSDK] isCachedAdAvailable])
    {
        [self.delegate interstitialCustomEvent: self didLoadAd: nil];
    }
}

- (void)showInterstitialFromRootViewController:(UIViewController *)rootViewController
{
    if([[VungleSDK sharedSDK] isCachedAdAvailable])
    {
        [[VungleSDK sharedSDK] playAd: rootViewController];
    }
    else
    {
        MPLogInfo(@"Failed to show Vungle video interstitial: Vungle now claims that there is no available video ad.");
        [self.delegate interstitialCustomEvent:self didFailToLoadAdWithError:nil];
    }
}

- (void)dealloc
{
    [self clearSelfAsVGDelegate];
    
    [super dealloc];
}

- (void)invalidate
{
    [self clearSelfAsVGDelegate];
}

- (void)clearSelfAsVGDelegate
{
    // if we're the current delegate, nil it out
    if([[VungleSDK sharedSDK] delegate] == self)
    {
        [[VungleSDK sharedSDK] setDelegate:nil];
    }
}

#pragma mark - VGVunglePubDelegate

- (void)vungleSDKwillShowAd
{
    MPLogInfo(@"Vungle video interstitial will appear");
    [self.delegate interstitialCustomEventWillAppear:self];
    [self.delegate interstitialCustomEventDidAppear:self];
}

/**
 * if implemented, this will get called when the SDK closes the ad view, but there might be
 * a product sheet that will be presented. This point might be a good place to resume your game
 * if there's no product sheet being presented. The viewInfo dictionary will contain the
 * following keys:
 * - "completedView": NSNumber representing a BOOL whether or not the video can be considered a
 *               full view.
 * - "playTime": NSNumber representing the time in seconds that the user watched the video.
 * - "didDownlaod": NSNumber representing a BOOL whether or not the user clicked the download
 *                  button.
 */
- (void)vungleSDKwillCloseAdWithViewInfo:(NSDictionary*)viewInfo willPresentProductSheet:(BOOL)willPresentProductSheet
{
    if(!willPresentProductSheet)
    {
        MPLogInfo(@"Vungle video interstitial did disappear");
    
        [self.delegate interstitialCustomEventWillDisappear:self];
        [self.delegate interstitialCustomEventDidDisappear:self];
    }
}

/**
 * if implemented, this will get called when the product sheet is about to be closed.
 */
- (void)vungleSDKwillCloseProductSheet:(id)productSheet
{
    MPLogInfo(@"Vungle video interstitial did disappear");
    
    [self.delegate interstitialCustomEventWillDisappear:self];
    [self.delegate interstitialCustomEventDidDisappear:self];
}


- (void)vungleSDKhasCachedAdAvailable
{
    MPLogInfo(@"Vungle video has cached ad available.");
    [self.delegate interstitialCustomEvent: self didLoadAd: nil];
}

@end
