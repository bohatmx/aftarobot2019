package com.aftarobot.commuter;

import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.support.v4.content.LocalBroadcastManager;
import android.util.Log;

import com.google.android.gms.nearby.Nearby;
import com.google.android.gms.nearby.messages.Message;
import com.google.android.gms.nearby.messages.MessageListener;
import com.google.android.gms.nearby.messages.MessagesClient;
import com.google.android.gms.nearby.messages.Strategy;
import com.google.android.gms.nearby.messages.SubscribeOptions;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import java.util.Date;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
    public static final String TAG = "VehicleWildSide";
    public static final Gson G = new GsonBuilder().setPrettyPrinting().create();
    MessageListener mMessageListener;
    Message mMessage;
    private static final String TAXI_MESSAGE_CHANNEL = "aftarobot/messages";
    EventChannel.EventSink messageEvents;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        GeneratedPluginRegistrant.registerWith(this);

        Log.d(TAG, "\n\nonCreate: \uD83D\uDD35 \uD83D\uDD35 \uD83D\uDD35 set up Taxi Message Channel");

        new EventChannel(getFlutterView(), TAXI_MESSAGE_CHANNEL).setStreamHandler(
                new EventChannel.StreamHandler() {

                    @Override
                    public void onListen(Object arguments, EventChannel.EventSink events) {
                        Log.d(TAG, "\n\n### onListen ++++ \uD83D\uDCCD \uD83D\uDCCD EventChannel ready to go ... waiting to publish and subscribe. - "
                                + new Date().toString());
                        messageEvents = events;
                        Log.d(TAG, "onCreate: \uD83D\uDD35 \uD83D\uDD35 ### trying ... MessagesClient publish and subscribe ");

                        String s = "AftaRobot Commuter :: FG "  + new Date().getTime();
                        mMessage = new Message(s.getBytes());

                        startMessageListener();
                        fgMessagesClient = Nearby.getMessagesClient(MainActivity.this);
                        fgPublishClient = Nearby.getMessagesClient(MainActivity.this);

                        fgPublishClient.publish(mMessage);
                        fgMessagesClient.subscribe(mMessageListener);
                        Log.d(TAG, "onCreate: \uD83D\uDD35 \uD83D\uDD35 ### MessagesClient published and subscribed!!! ");
                    }

                    @Override
                    public void onCancel(Object arguments) {
                        Log.d(TAG, "--- onCancel:  \uD83C\uDFBE  \uD83C\uDFBE cancelling EventChannel ..." + new Date().toString());
                    }
                }
        );


    }

    void startMessageListener() {
        Log.d(TAG, "startMessageListener: +++ \uD83D\uDCCD \uD83D\uDCCD  set up Message Listener");
        mMessageListener = new MessageListener() {
            @Override
            public void onFound(Message message) {
                Log.d(TAG, " ✅ Found message: " + new String(message.getContent()));
                messageEvents.success(new String(message.getContent()));
            }

            @Override
            public void onLost(Message message) {
                Log.d(TAG, "\uD83C\uDFBE \uD83C\uDFBE  Lost sight of message: " + new String(message.getContent()));
            }
        };
        Log.d(TAG, "startMessageListener: \uD83D\uDCCD listen for broadcast from TaxiMessageReceiver");
        IntentFilter filter = new IntentFilter(
                TaxiMessageReceiver.MESSAGE_RECEIVED_INTENT);
        LocalBroadcastManager.getInstance(this)
                .registerReceiver(new TaxiBroadcastReceiver(), filter);
        backgroundSubscribe();
        Log.d(TAG, "startMessageListener: \uD83D\uDD35 MessageListener started. Fingers crossed :)");
    }

    // Subscribe to messages in the background.
    MessagesClient bgMessagesClient, fgMessagesClient, fgPublishClient, bgPublishClient;

    private void backgroundSubscribe() {
        Log.i(TAG, "\uD83D\uDCCD \uD83D\uDCCD Subscribing for background TAXI messages....");
        SubscribeOptions options = new SubscribeOptions.Builder()
                .setStrategy(Strategy.BLE_ONLY)
                .build();
        bgMessagesClient = Nearby.getMessagesClient(this);
        bgMessagesClient.subscribe(getPendingIntent(),options);

        bgPublishClient = Nearby.getMessagesClient(this);
        String s = "AftaRobot Commuter :: BG "  + new Date().getTime();
        mMessage = new Message(s.getBytes());
        bgPublishClient.publish(mMessage);

    }

    private PendingIntent getPendingIntent() {
        return PendingIntent.getBroadcast(this, 0, new Intent(this, TaxiMessageReceiver.class),
                PendingIntent.FLAG_UPDATE_CURRENT);
    }
    public class TaxiBroadcastReceiver extends BroadcastReceiver {

        @Override
        public void onReceive(Context context, Intent intent) {
            String message = intent.getStringExtra("message");
            Log.d(TAG, "TaxiBroadcastReceiver \uD83D\uDCCD onReceive: sending message to Flutter");
            messageEvents.success(message);
        }
    }
    @Override
    public void onStart() {
        super.onStart();
        Log.d(TAG, "onStart: \uD83D\uDD35  \uD83D\uDD35 ### do nuthin ... ");

    }

    @Override
    public void onStop() {
        fgPublishClient.unpublish(mMessage);
        bgPublishClient.unpublish(mMessage);
        bgMessagesClient.unsubscribe(mMessageListener);
        fgMessagesClient.unsubscribe(mMessageListener);
        super.onStop();
        Log.d(TAG, "onStop: ###  \uD83C\uDFBE \uD83C\uDFBE MessagesClient un-publish and unsubscribe ");
    }
}

