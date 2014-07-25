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

public class AmazonBanner extends CustomEventBanner implements AdListener {

	private static final String APP_KEY = "app-key"; 													
	private static final String LOG_TAG = "DoodleJump";
	private AdLayout mAdView;
	private CustomEventBannerListener mBannerListener;

	@Override
	protected void loadBanner(Context context,
			CustomEventBannerListener customEventBannerListener,
			Map<String, Object> localExtras, Map<String, String> serverExtras) {

        if (!(context instanceof Activity)) {
            customEventBannerListener.onBannerFailed(MoPubErrorCode.ADAPTER_CONFIGURATION_ERROR);
            return;
        }

        Activity activity = (Activity) context;

        if (extrasAreValid(serverExtras)) {
            if(!AmazonRegistration.isRegistrationComplete()) {
                if(!AmazonRegistration.RegisterApplication(activity, serverExtras.get(APP_KEY))) {
                    customEventBannerListener.onBannerFailed(MoPubErrorCode.ADAPTER_CONFIGURATION_ERROR);
                }
            }
        } else {
            customEventBannerListener.onBannerFailed(MoPubErrorCode.ADAPTER_CONFIGURATION_ERROR);
            return;
        }

        mBannerListener = customEventBannerListener;

		if (mAdView == null) {
			mAdView = new AdLayout(activity);
			LayoutParams layoutParams = new FrameLayout.LayoutParams(
					LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT,
					Gravity.CENTER | Gravity.CENTER_HORIZONTAL);
			mAdView.setLayoutParams(layoutParams);
			mAdView.setListener(this);
		}

		AdTargetingOptions adOptions = new AdTargetingOptions();

        if(!mAdView.isLoading()) {
            boolean didLoadAdWithSuccess = mAdView.loadAd(adOptions);
            if (!didLoadAdWithSuccess) {
                mBannerListener.onBannerFailed(MoPubErrorCode.INTERNAL_ERROR);
            }
        }
    }

    private boolean extrasAreValid(Map<String, String> serverExtras)
    {
        return serverExtras.containsKey(APP_KEY);
    }

    @Override
	public void onAdCollapsed(Ad arg0)
    {
		mBannerListener.onBannerCollapsed();
	}

	@Override
	public void onAdExpanded(Ad arg0)
    {
		mBannerListener.onBannerExpanded();
	}

	@Override
	public void onAdFailedToLoad(Ad arg0, AdError error)
    {
        if(error.getCode() == AdError.ErrorCode.NETWORK_ERROR)
        {
            mBannerListener.onBannerFailed(MoPubErrorCode.SERVER_ERROR);
        }
        else if(error.getCode() == AdError.ErrorCode.NO_FILL)
        {
            mBannerListener.onBannerFailed(MoPubErrorCode.NO_FILL);
        }
        else if(error.getCode() == AdError.ErrorCode.INTERNAL_ERROR || error.getCode() == AdError.ErrorCode.REQUEST_ERROR)
        {
            mBannerListener.onBannerFailed(MoPubErrorCode.INTERNAL_ERROR);
        }
        else
        {
            mBannerListener.onBannerFailed(MoPubErrorCode.UNSPECIFIED);
        }
    }

	@Override
	public void onAdLoaded(Ad arg0, AdProperties arg1)
    {
        mBannerListener.onBannerLoaded(mAdView);
	}

    @Override
    public void onAdDismissed(Ad ad)
    {
        // for interstitials only
    }

	@Override
	protected void onInvalidate()
    {
        // clean-up
        if(mAdView != null)
        {
            mAdView.setListener(null);
            mAdView.destroy();
            mAdView = null;
        }
	}
}