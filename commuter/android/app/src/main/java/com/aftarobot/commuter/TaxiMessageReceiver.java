package com.aftarobot.commuter;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.support.v4.content.LocalBroadcastManager;
import android.util.Log;

import com.google.android.gms.nearby.Nearby;
import com.google.android.gms.nearby.messages.Message;
import com.google.android.gms.nearby.messages.MessageListener;

public class TaxiMessageReceiver extends BroadcastReceiver {
    public static final String TAG = TaxiMessageReceiver.class.getSimpleName();
    public static final String MESSAGE_RECEIVED_INTENT = "com.aftarobot.MESSAGE_RECEIVED_INTENT";
    @Override
    public void onReceive(final Context context, Intent intent) {
        Log.d(TAG, "\nonReceive: ##### - \uD83D\uDD35 - \uD83D\uDD35  RECEIVED IN BACKGROUND!!!!");
        Nearby.getMessagesClient(context).handleIntent(intent, new MessageListener() {
            @Override
            public void onFound(Message message) {
                Log.d(TAG, "\n\n✅ Found message, in background: " + new String(message.getContent()));
                LocalBroadcastManager localBroadcastManager = LocalBroadcastManager.getInstance(context);
                Intent m = new Intent(MESSAGE_RECEIVED_INTENT);
                m.putExtra("message", new String(message.getContent()));
                localBroadcastManager.sendBroadcast(m);
            }

            @Override
            public void onLost(Message message) {
                Log.i(TAG, "\uD83C\uDFBE Lost message via PendingIntent: " + message);
            }
        });
    }
}
