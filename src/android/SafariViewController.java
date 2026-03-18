package com.outsystems.safariviewcontroller;

import android.net.Uri;

import androidx.browser.customtabs.CustomTabsClient;
import androidx.browser.customtabs.CustomTabsIntent;
import androidx.browser.customtabs.CustomTabsServiceConnection;
import androidx.browser.customtabs.CustomTabsSession;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

public class SafariViewController extends CordovaPlugin {

    private CustomTabsClient customTabsClient;
    private CustomTabsSession customTabsSession;
    private CustomTabsServiceConnection connection;

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        switch (action) {
            case "isAvailable":
                callbackContext.success();
                return true;

            case "show":
                show(args, callbackContext);
                return true;

            case "hide":
                callbackContext.success();
                return true;

            case "connectToService":
                connectToService(callbackContext);
                return true;

            case "warmUp":
                warmUp(callbackContext);
                return true;

            case "mayLaunchUrl":
                mayLaunchUrl(args, callbackContext);
                return true;

            default:
                return false;
        }
    }

    private void show(JSONArray args, CallbackContext callbackContext) {
        try {
            JSONObject options = args.optJSONObject(0);
            String url = options != null ? options.optString("url", null) : null;

            if (url == null || url.trim().isEmpty()) {
                callbackContext.error("Missing url");
                return;
            }

            CustomTabsIntent.Builder builder = customTabsSession != null
                    ? new CustomTabsIntent.Builder(customTabsSession)
                    : new CustomTabsIntent.Builder();

            CustomTabsIntent intent = builder.build();
            intent.intent.setData(Uri.parse(url));
            cordova.getActivity().runOnUiThread(() ->
                    intent.launchUrl(cordova.getActivity(), Uri.parse(url))
            );

            callbackContext.success();
        } catch (Exception e) {
            callbackContext.error(e.getMessage());
        }
    }

    private void connectToService(CallbackContext callbackContext) {
        try {
            if (connection != null) {
                callbackContext.success();
                return;
            }

            String packageName = CustomTabsClient.getPackageName(cordova.getContext(), null);
            if (packageName == null) {
                callbackContext.error("No Custom Tabs provider found");
                return;
            }

            connection = new CustomTabsServiceConnection() {
                @Override
                public void onCustomTabsServiceConnected(android.content.ComponentName name, CustomTabsClient client) {
                    customTabsClient = client;
                    customTabsClient.warmup(0L);
                    customTabsSession = customTabsClient.newSession(null);
                }

                @Override
                public void onServiceDisconnected(android.content.ComponentName name) {
                    customTabsClient = null;
                    customTabsSession = null;
                    connection = null;
                }
            };

            boolean ok = CustomTabsClient.bindCustomTabsService(cordova.getContext(), packageName, connection);
            if (ok) callbackContext.success();
            else callbackContext.error("Could not bind Custom Tabs service");
        } catch (Exception e) {
            callbackContext.error(e.getMessage());
        }
    }

    private void warmUp(CallbackContext callbackContext) {
        try {
            if (customTabsClient != null) {
                customTabsClient.warmup(0L);
            }
            callbackContext.success();
        } catch (Exception e) {
            callbackContext.error(e.getMessage());
        }
    }

    private void mayLaunchUrl(JSONArray args, CallbackContext callbackContext) {
        try {
            JSONObject options = args.optJSONObject(0);
            String url = options != null ? options.optString("url", null) : null;

            if (url == null || url.trim().isEmpty()) {
                callbackContext.error("Missing url");
                return;
            }

            if (customTabsSession != null) {
                customTabsSession.mayLaunchUrl(Uri.parse(url), null, null);
            }

            callbackContext.success();
        } catch (Exception e) {
            callbackContext.error(e.getMessage());
        }
    }
}