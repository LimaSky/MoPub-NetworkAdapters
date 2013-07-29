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

#import "AdColonyVideoCustomEvent.h"
#import "MPLogging.h"

////////////////////////////////////////////////////////////////////////////////////////////////////

@interface MPAdColonyRouter ()

@property (nonatomic, retain) NSMutableDictionary *events;
@property (nonatomic, retain) NSMutableSet *activeZones;
@property (nonatomic, copy) NSString* appId;
@property (nonatomic, copy) NSDictionary* adZones;

- (void)registerAdColonyVideoCustomEvent:(AdColonyVideoCustomEvent *)event forZoneId:(NSString*) zoneId;
- (AdColonyVideoCustomEvent *)eventForZone:(NSString *)zoneId;
- (void)setEvent:(AdColonyVideoCustomEvent *)event forZone:(NSString *)zoneId;
- (void)unregisterEventForZone:(NSString *)zoneId;
- (BOOL)hasCachedInterstitialForZone:(NSString *)zoneId;
- (void)showInterstitialForZone:(NSString *)zoneId;
- (void)unregisterEvent:(AdColonyVideoCustomEvent *)event;
- (NSInteger) statusForZone: (NSString*) zoneId;
@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@interface AdColonyVideoCustomEvent ()

@property (nonatomic, retain) NSString *zone;

@end

@implementation AdColonyVideoCustomEvent

@synthesize zone = _zone;

- (void)dealloc
{
    [[MPAdColonyRouter sharedRouter] unregisterEvent:self];
    self.zone = nil;
    
    [super dealloc];
}

#pragma mark - AdColonyVideoCustomEvent Subclass Methods

- (void)requestInterstitialWithCustomEventInfo:(NSDictionary *)info
{
    NSString *appId = [info objectForKey:@"appId"];
    NSString *zone = [info objectForKey:@"zone"]; // This ad is tied to this Zone ID.
    NSString *zones = [info objectForKey:@"zones"]; // This is a list of all valid Zone Ids.
    if (appId && zone && zones) {
		self.zone = zone;
            
        if(![MPAdColonyRouter sharedRouter]) {
            // If we're initializing AdColony for the first time, we need to build an Ad Zone
            // dictionary that maps all the valid Zone Ids to some arbitrary Slot Numbers.
            NSMutableArray* zoneIds = [[NSMutableArray alloc] init];
            NSMutableArray* slotNumbers = [[NSMutableArray alloc] init];
            int slotNumber = 1;
            
            NSArray* zoneIdsArray = [zones componentsSeparatedByString: @","];
            
            for(NSString* zoneId in zoneIdsArray) {
                [zoneIds addObject:zoneId];
                [slotNumbers addObject:[NSNumber numberWithInteger:slotNumber]];
                ++slotNumber;
            }
            
            NSDictionary* adZonesDictionary = [[NSDictionary alloc] initWithObjects:zoneIds forKeys:slotNumbers];
            [zoneIds release];
            [slotNumbers release];
            
            [MPAdColonyRouter createSharedRouter:appId withAdZones:adZonesDictionary];
            [adZonesDictionary release];
            
            // Since AdColony was just created, it's pointless to check the status of any of the
            // ads being requested for our zones. We will register the custom event associated
            // with this zone, and wait for callbacks associated with it to reach us.
            
            MPLogInfo(@"Requesting AdColony video for zone: %@.", self.zone);
            [[MPAdColonyRouter sharedRouter] registerAdColonyVideoCustomEvent: self
                                     forZoneId:self.zone];           
        }
        else
        {
            // Since AdColony has already been created and initialized sometime in the past,
            // there is a chance that we already have an ad associated with this zone, so we're
            // going to check its status and automate the appropriate delegate calls.
            
            MPLogInfo(@"Requesting AdColony video for zone: %@.", self.zone);
            [[MPAdColonyRouter sharedRouter] registerAdColonyVideoCustomEvent: self
                                     forZoneId:self.zone];
            
            NSInteger zoneStatus = [[MPAdColonyRouter sharedRouter] statusForZone: self.zone];
            
            MPLogInfo(@"AdColony zone status: %d for %@.", zoneStatus, self.zone);
            
            switch(zoneStatus)
            {
                case ADCOLONY_ZONE_STATUS_ACTIVE:
                {
                    [self.delegate interstitialCustomEvent:self didLoadAd:nil];
                    break;
                }
                
                case ADCOLONY_ZONE_STATUS_LOADING:
                {
                    // wait for callback
                    break;
                }
                
                default:
                {
                    [self.delegate interstitialCustomEvent:self didFailToLoadAdWithError:nil]; 
                    break;
                }
            }
        }

	}
}

- (void)showInterstitialFromRootViewController:(UIViewController *)rootViewController
{
    if ([[MPAdColonyRouter sharedRouter] hasCachedInterstitialForZone:self.zone]) {
        MPLogInfo(@"AdColony video will be shown.");
        [[MPAdColonyRouter sharedRouter] showInterstitialForZone:self.zone];        
    } else {
        MPLogInfo(@"Failed to show AdColony video.");
        [self.delegate interstitialCustomEvent:self didFailToLoadAdWithError:nil];
    }
}

#pragma mark - AdColonyDelegate

- (void)didFailToLoadForZone:(NSString *)zone
{
    MPLogInfo(@"Failed to load AdColony video.");
    [self.delegate interstitialCustomEvent:self didFailToLoadAdWithError:nil];
}

- (void) adColonyVideoAdsReadyInZone:(NSString *)zone
{
    MPLogInfo(@"AdColony video ready in zone: %@.", zone);
    [self.delegate interstitialCustomEvent:self didLoadAd:nil];
}

- (void)takeoverBeganForZone:(NSString *)zone
{
    MPLogInfo(@"Successfully loaded AdColony video.");
    [self.delegate interstitialCustomEventWillAppear:self];
    [self.delegate interstitialCustomEventDidAppear:self];    
}

- (void)takeoverEndedForZone:(NSString *)zone
{
    MPLogInfo(@"AdColony video was dismissed.");

    [self.delegate interstitialCustomEventWillDisappear:self];
    [self.delegate interstitialCustomEventDidDisappear:self];
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

/*
 * AdColony only provides a shared instance, so only one object may be the AdColony delegate at
 * any given time. However, because it is common to request AdColony interstitials for separate
 * "zones" in a single app session, we may have multiple instances of our custom event class,
 * all of which are interested in delegate callbacks.
 *
 * MPAdColonyRouter is a singleton that is always the AdColony delegate, and dispatches
 * events to all of the custom event instances.
 */

@implementation MPAdColonyRouter

@synthesize events = _events;
@synthesize activeZones = _activeZones;
@synthesize appId = _appId;
@synthesize adZones = _adZones;

static MPAdColonyRouter *sharedRouter = nil;

+ (MPAdColonyRouter *)createSharedRouter: (NSString *)appId withAdZones: (NSDictionary*) adZones
{
    if(!sharedRouter && appId && adZones) {
        sharedRouter = [[MPAdColonyRouter alloc] init: appId withAdZones: adZones];
    }
    return sharedRouter;
}

+ (MPAdColonyRouter *)sharedRouter
{
    return sharedRouter;
}

- (id)init: (NSString *)appId withAdZones: (NSDictionary*) adZones
{
    self = [super init];
    if (self)
    {
        self.events = [NSMutableDictionary dictionary];
        self.activeZones = [NSMutableSet set];
        self.appId = appId;
        self.adZones = adZones;
        
		[AdColony initAdColonyWithDelegate:self];
    }
    return self;
}

- (void)dealloc
{
    [_events release];
    [_activeZones release];
    [_adZones release];
    [_appId release];
    [super dealloc];
}

- (void)registerAdColonyVideoCustomEvent:(AdColonyVideoCustomEvent *)event forZoneId:(NSString*) zoneId
{
    if ([self.activeZones containsObject:zoneId]) {
        MPLogInfo(@"Failed to load AdColony video: this zone is already in use.");
        [event didFailToLoadForZone:zoneId];
        return;
    }

    if ([zoneId length] > 0) {
        [self setEvent:event forZone:zoneId];
    } else {
        MPLogInfo(@"Failed to load AdColony video: missing zoneId.");
        [event didFailToLoadForZone:zoneId];
    }
}

- (BOOL)hasCachedInterstitialForZone:(NSString *)zoneId
{
    return [AdColony zoneStatusForZone:zoneId] == ADCOLONY_ZONE_STATUS_ACTIVE;
}

- (NSInteger) statusForZone: (NSString*) zoneId
{
    return [AdColony zoneStatusForZone:zoneId];
}

- (void)showInterstitialForZone:(NSString *)zoneId
{
    [AdColony playVideoAdForZone:zoneId withDelegate:self];
}

- (AdColonyVideoCustomEvent *)eventForZone:(NSString *)zoneId
{
    return [self.events objectForKey:zoneId];
}

- (void)setEvent:(AdColonyVideoCustomEvent *)event forZone:(NSString *)zoneId
{
    MPLogInfo(@"Setting AdColony event %@ for zone %@.", event, zoneId);
    [self.events setObject:event forKey:zoneId];
    [self.activeZones addObject:zoneId];
}

- (void)unregisterEventForZone:(NSString *)zoneId
{
    [self.activeZones removeObject:zoneId];
    [self.events removeObjectForKey:zoneId];
}

- (void)unregisterEvent:(AdColonyVideoCustomEvent *)event
{
    if ([[self.events objectForKey:event.zone] isEqual:event]) {
        [self unregisterEventForZone:event.zone];
    }
}

#pragma mark - AdColonyDelegate

- (NSString *)adColonyApplicationID {
    return _appId;
}

- (NSDictionary *)adColonyAdZoneNumberAssociation {
	return _adZones;
}

#pragma mark - AdColonyTakeoverAdDelegate

- (void)adColonyVideoAdNotServedForZone:(NSString *)zone {
    MPLogInfo(@"adColonyVideoAdNotServedForZone");
    AdColonyVideoCustomEvent* event = [self eventForZone:zone];
    if(event) {
        [event didFailToLoadForZone:zone];
    }
    [self unregisterEventForZone:zone];    
}

- (void)adColonyVideoAdsReadyInZone:( NSString * )zone {
    MPLogInfo(@"adColonyVideoAdsReadyInZone");
    AdColonyVideoCustomEvent* event = [self eventForZone:zone];
    if(event) {
        [event adColonyVideoAdsReadyInZone:zone];
    }
}

- (void) adColonyTakeoverBeganForZone:(NSString *)zone {
    MPLogInfo(@"adColonyTakeoverBeganForZone");
    AdColonyVideoCustomEvent* event = [self eventForZone:zone];
    if(event) {
        [event takeoverBeganForZone:zone];
    }
}

- (void)adColonyTakeoverEndedForZone:(NSString *)zone withVC:(BOOL)withVirtualCurrencyAward {
    MPLogInfo(@"adColonyTakeoverEndedForZone");
    AdColonyVideoCustomEvent* event = [self eventForZone:zone];
    if(event) {
        [event takeoverEndedForZone:zone];
    }
    [self unregisterEventForZone:zone];    
}

@end
