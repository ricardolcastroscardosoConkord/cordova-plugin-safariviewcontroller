package com.outsystems.safariviewcontroller;

import android.content.Intent;
import android.net.Uri;

import androidx.browser.customtabs.CustomTabsClient;
import androidx.browser.customtabs.CustomTabsIntent;
import androidx.browser.customtabs.CustomTabsServiceConnection;
import androidx.browser.customtabs.CustomTabsSession;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
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
                callbackContext.success(1);
                return true;

            case "show":
                show(args, callbackContext);
                return true;

            case "hide":
                hide(callbackContext);
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
            JSONObject options = args != null ? args.optJSONObject(0) : null;
            String url = options != null ? options.optString("url", null) : null;

            if (url == null || url.trim().isEmpty()) {
                callbackContext.error("Missing url");
                return;
            }

            final Uri uri = Uri.parse(url.trim());

            cordova.getActivity().runOnUiThread(() -> {
                try {
                    sendEvent(callbackContext, "opened");

                    CustomTabsIntent.Builder builder =
                            customTabsSession != null
                                    ? new CustomTabsIntent.Builder(customTabsSession)
                                    : new CustomTabsIntent.Builder();

                    builder.setShowTitle(true);

                    CustomTabsIntent customTabsIntent = builder.build();
                    customTabsIntent.intent.addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY);

                    try {
                        customTabsIntent.launchUrl(cordova.getActivity(), uri);
                        sendEvent(callbackContext, "loaded");
                    } catch (Exception customTabsError) {
                        try {
                            Intent fallbackIntent = new Intent(Intent.ACTION_VIEW, uri);
                            fallbackIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                            cordova.getActivity().startActivity(fallbackIntent);
                            sendEvent(callbackContext, "loaded");
                        } catch (Exception fallbackError) {
                            callbackContext.error("Could not open url: " + fallbackError.getMessage());
                        }
                    }
                } catch (Exception e) {
                    callbackContext.error("Show failed: " + e.getMessage());
                }
            });

        } catch (Exception e) {
            callbackContext.error("Show failed: " + e.getMessage());
        }
    }

    private void hide(CallbackContext callbackContext) {
        try {
            JSONObject result = new JSONObject();
            result.put("event", "closed");

            PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, result);
            pluginResult.setKeepCallback(false);
            callbackContext.sendPluginResult(pluginResult);
        } catch (Exception e) {
            callbackContext.success();
        }
    }

    private void connectToService(CallbackContext callbackContext) {
        try {
            if (connection != null) {
                callbackContext.success();
                return;
            }

            String packageName = CustomTabsClient.getPackageName(cordova.getContext(), null);
            if (packageName == null || packageName.trim().isEmpty()) {
                callbackContext.success();
                return;
            }

            connection = new CustomTabsServiceConnection() {
                @Override
                public void onCustomTabsServiceConnected(android.content.ComponentName name, CustomTabsClient client) {
                    customTabsClient = client;
                    try {
                        customTabsClient.warmup(0L);
                        customTabsSession = customTabsClient.newSession(null);
                    } catch (Exception ignored) {
                    }
                }

                @Override
                public void onServiceDisconnected(android.content.ComponentName name) {
                    customTabsClient = null;
                    customTabsSession = null;
                    connection = null;
                }
            };

            boolean ok = CustomTabsClient.bindCustomTabsService(cordova.getContext(), packageName, connection);
            if (ok) {
                callbackContext.success();
            } else {
                callbackContext.success();
            }
        } catch (Exception e) {
            callbackContext.success();
        }
    }

    private void warmUp(CallbackContext callbackContext) {
        try {
            if (customTabsClient != null) {
                customTabsClient.warmup(0L);
            }
            callbackContext.success();
        } catch (Exception e) {
            callbackContext.success();
        }
    }

    private void mayLaunchUrl(JSONArray args, CallbackContext callbackContext) {
        try {
            JSONObject options = args != null ? args.optJSONObject(0) : null;
            String url = options != null ? options.optString("url", null) : null;

            if (url != null && !url.trim().isEmpty() && customTabsSession != null) {
                customTabsSession.mayLaunchUrl(Uri.parse(url.trim()), null, null);
            }

            callbackContext.success();
        } catch (Exception e) {
            callbackContext.success();
        }
    }

    private void sendEvent(CallbackContext callbackContext, String eventName) throws JSONException {
        JSONObject result = new JSONObject();
        result.put("event", eventName);

        PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, result);
        pluginResult.setKeepCallback(true);
        callbackContext.sendPluginResult(pluginResult);
    }
}
