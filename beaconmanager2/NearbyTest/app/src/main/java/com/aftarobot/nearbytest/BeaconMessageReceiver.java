package com.aftarobot.nearbytest;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

import com.google.android.gms.nearby.Nearby;
import com.google.android.gms.nearby.messages.Message;
import com.google.android.gms.nearby.messages.MessageListener;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

public class BeaconMessageReceiver extends BroadcastReceiver {
    private static final Gson GS = new GsonBuilder().setPrettyPrinting().create();
    static final String TAG = "BeaconMessageReceiver";

    @Override
    public void onReceive(Context context, Intent intent) {
        Nearby.getMessagesClient(context).handleIntent(intent, new MessageListener() {
            @Override
            public void onFound(Message message) {
                Log.i(TAG, "Found message via PendingIntent: " + message);
                Log.d(TAG, "onFound: #### " + GS.toJson(message));
            }

            @Override
            public void onLost(Message message) {
                Log.i(TAG, "Lost message via PendingIntent: " + message);
                Log.d(TAG, "onFound: #### " + GS.toJson(message));
            }
        });
    }
}
