package com.mopub.mobileads;

import java.lang.Override;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;

import android.app.Activity;
import android.content.Context;
import android.util.Log;
import android.view.Gravity;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.FrameLayout.LayoutParams;

import com.amazon.device.ads.*;

public class AmazonInterstitial extends CustomEventInterstitial implements AdListener
{
    private static final String APP_KEY = "app-key";
    private static final String LOG_TAG = "DoodleJump";

    InterstitialAd mInterstitialAd;
    CustomEventInterstitialListener mCustomEventInterstitialListener;

    @Override
    protected void loadInterstitial(Context context,
                                    CustomEventInterstitialListener customEventInterstitialListener,
                                    Map<String, Object> localExtras,
                                    Map<String, String> serverExtras)
    {
        if (!(context instanceof Activity)) {
            customEventInterstitialListener.onInterstitialFailed(MoPubErrorCode.ADAPTER_CONFIGURATION_ERROR);
            return;
        }

        Activity activity = (Activity) context;
        mCustomEventInterstitialListener = customEventInterstitialListener;

        if (extrasAreValid(serverExtras)) {
            if(!AmazonRegistration.isRegistrationComplete()) {
                if(!AmazonRegistration.RegisterApplication(activity, serverExtras.get(APP_KEY))) {
                    customEventInterstitialListener.onInterstitialFailed(MoPubErrorCode.ADAPTER_CONFIGURATION_ERROR);
                }
            }
        } else {
            customEventInterstitialListener.onInterstitialFailed(MoPubErrorCode.ADAPTER_CONFIGURATION_ERROR);
            return;
        }

        mInterstitialAd = new InterstitialAd(activity);
        mInterstitialAd.setListener(this);
        if(!mInterstitialAd.isLoading()) {
            boolean didLoadAdWithSuccess = mInterstitialAd.loadAd();
            if(!didLoadAdWithSuccess) {
                customEventInterstitialListener.onInterstitialFailed(MoPubErrorCode.INTERNAL_ERROR);
            }
        }
    }

    private boolean extrasAreValid(Map<String, String> serverExtras)
    {
        return serverExtras.containsKey(APP_KEY);
    }

    protected void showInterstitial()
    {
        if(!mInterstitialAd.isShowing()) {
            mInterstitialAd.showAd();
        } else {
            mCustomEventInterstitialListener.onInterstitialFailed(MoPubErrorCode.INTERNAL_ERROR);
        }
    }

    protected void onInvalidate()
    {
        if (mInterstitialAd != null) {
            mInterstitialAd.setListener(null);
            mInterstitialAd = null;
        }
    }

    @Override
    public void onAdCollapsed(Ad arg0)
    {
        // applies to banners only
        //Log.i(LOG_TAG, "Interstitial OnAdCollpased");
    }

    @Override
    public void onAdExpanded(Ad arg0)
    {
        //Log.i(LOG_TAG, "Interstitial onAdExpanded");
    }

    @Override
    public void onAdFailedToLoad(Ad arg0, AdError error)
    {
        if(error.getCode() == AdError.ErrorCode.NETWORK_ERROR)
        {
            mCustomEventInterstitialListener.onInterstitialFailed(MoPubErrorCode.SERVER_ERROR);
        }
        else if(error.getCode() == AdError.ErrorCode.NO_FILL)
        {
            mCustomEventInterstitialListener.onInterstitialFailed(MoPubErrorCode.NO_FILL);
        }
        else if(error.getCode() == AdError.ErrorCode.INTERNAL_ERROR || error.getCode() == AdError.ErrorCode.REQUEST_ERROR)
        {
            mCustomEventInterstitialListener.onInterstitialFailed(MoPubErrorCode.INTERNAL_ERROR);
        }
        else
        {
            mCustomEventInterstitialListener.onInterstitialFailed(MoPubErrorCode.UNSPECIFIED);
        }
    }

    @Override
    public void onAdLoaded(Ad arg0, AdProperties arg1)
    {
        mCustomEventInterstitialListener.onInterstitialLoaded();
    }

    @Override
    public void onAdDismissed(Ad ad)
    {
        mCustomEventInterstitialListener.onInterstitialShown();
        mCustomEventInterstitialListener.onInterstitialDismissed();
    }
}
