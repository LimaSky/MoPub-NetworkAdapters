package com.mopub.mobileads;

import android.app.Activity;
import com.lima.doodlejump.BuildConfig;
import com.amazon.device.ads.AdRegistration;

public class AmazonRegistration
{
    static private String appKey = "";
    static private boolean isRegistrationComplete = false;

    static public String getAppKey()
    {
        return appKey;
    }

    static public boolean isRegistrationComplete()
    {
        return isRegistrationComplete;
    }

    static public boolean RegisterApplication(Activity activity, String amazonAppKey)
    {
        try {
            if (!isRegistrationComplete()) {
                AdRegistration.setAppKey(amazonAppKey);
                appKey = amazonAppKey;

                boolean enableFeature = BuildConfig.DEBUG;
                AdRegistration.enableLogging(enableFeature);
                AdRegistration.enableTesting(enableFeature);
                //com.amazon.device.ads.AdRegistration.registerApp(activity);
                isRegistrationComplete = true;
            }
        }
        catch(Exception e)
        {
        }
        return isRegistrationComplete;
    }
}
