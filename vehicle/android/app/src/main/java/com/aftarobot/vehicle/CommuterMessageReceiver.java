package com.aftarobot.vehicle;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.support.v4.content.LocalBroadcastManager;

import com.aftarobot.vehicle.log.LogFileWriter;
import com.google.android.gms.nearby.Nearby;
import com.google.android.gms.nearby.messages.Message;
import com.google.android.gms.nearby.messages.MessageListener;

public class CommuterMessageReceiver extends BroadcastReceiver {

    public static final String TAG = CommuterMessageReceiver.class.getSimpleName();
    public static final String MESSAGE_RECEIVED_INTENT = "com.aftarobot.MESSAGE_RECEIVED_INTENT";
    @Override
    public void onReceive(final Context context, Intent intent) {
        LogFileWriter.print(TAG, "\nonReceive: ##### - \uD83D\uDD35 - \uD83D\uDD35  MESSAGE RECEIVED IN BACKGROUND!!!!");
        Nearby.getMessagesClient(context).handleIntent(intent, new MessageListener() {
            @Override
            public void onFound(Message message) {
                LogFileWriter.print(TAG, " ✅ Found commuter message, background: " + new String(message.getContent()));
                LocalBroadcastManager localBroadcastManager = LocalBroadcastManager.getInstance(context);
                Intent m = new Intent(MESSAGE_RECEIVED_INTENT);
                m.putExtra("message", new String(message.getContent()));
                localBroadcastManager.sendBroadcast(m);
            }

            @Override
            public void onLost(Message message) {
                LogFileWriter.print(TAG, "Lost commuter message; via PendingIntent: " + message);
            }
        });
    }
}

