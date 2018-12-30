package com.example.migrator2.beacons;

import android.content.Context;
import android.content.SharedPreferences;
import android.preference.PreferenceManager;
import android.util.Log;

public class SharedUtil {
    public static void saveAuthToken(String token, Context ctx) {
        SharedPreferences sp = PreferenceManager.getDefaultSharedPreferences(ctx);
        SharedPreferences.Editor ed = sp.edit();
        ed.putString("authtoken", token);
        ed.apply();
        Log.d(SharedUtil.class.getSimpleName(), "saveAuthToken " + token);
    }

    public static String getAuthToken(Context ctx) {
        if (ctx == null) return null;
        SharedPreferences sp = PreferenceManager.getDefaultSharedPreferences(ctx);
        String token = sp.getString("authtoken", null);
        return token;
    }
    public static void saveNamespace(String namespace, Context ctx) {
        SharedPreferences sp = PreferenceManager.getDefaultSharedPreferences(ctx);
        SharedPreferences.Editor ed = sp.edit();
        ed.putString("namespace", namespace);
        ed.apply();
        Log.d(SharedUtil.class.getSimpleName(), "saveNamespaceToken " + namespace);
    }

    public static String getNamespace(Context ctx) {
        if (ctx == null) return null;
        SharedPreferences sp = PreferenceManager.getDefaultSharedPreferences(ctx);
        String token = sp.getString("namespace", null);
        if (token != null)
            Log.w(SharedUtil.class.getSimpleName(), "getNamespace: " + token);
        return token;
    }

}
