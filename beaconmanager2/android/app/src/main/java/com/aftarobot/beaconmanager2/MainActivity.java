package com.aftarobot.beaconmanager2;

import android.os.Bundle;
import android.support.annotation.NonNull;
import android.util.Log;

import com.google.android.gms.nearby.Nearby;
import com.google.android.gms.nearby.messages.Message;
import com.google.android.gms.nearby.messages.MessageListener;
import com.google.android.gms.nearby.connection.
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import java.util.Arrays;
import java.util.Date;
import java.util.List;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
    private static final String BEACON_SCAN_CHANNEL = "aftarobot/beaconScan";
    private static final String BEACON_MONITOR_CHANNEL = "aftarobot/beaconMonitor";


    EventChannel.EventSink scanEvents, monitorEvents;
    static final String TAG = "The WildSide";
    MessageListener mMessageListener;
//    private static final List BEACON_TYPE_FILTERS = Arrays.asList(
//            BeaconState.TypeFilter.with(
//                    "my.beacon.namespace",
//                    "my-attachment-type"),
//            BeaconState.TypeFilter.with(
//                    "my.other.namespace",
//                    "my-attachment-type"));
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        GeneratedPluginRegistrant.registerWith(this);

        SnapshotApi
        processBeaconScan();
        new EventChannel(getFlutterView(), BEACON_MONITOR_CHANNEL).setStreamHandler(
                new EventChannel.StreamHandler() {

                    @Override
                    public void onListen(Object arguments, EventChannel.EventSink events) {
                        Log.d(TAG, "\n\n### +++++++++++++++++++++++++++   ℹ️  ℹ️  starting Beacon Monitor stream ..."
                                + new Date().toString());
                        monitorEvents = events;
                        try {
                            monitorEvents.success(GSON.toJson(new EventMessage("Started Monitoring for Beacons",0 )));
                            processMonitor();
                        } catch (Exception e) {
                            Log.e(TAG, "onListen: could not monitor beacons", e);
                            scanEvents.error("Unable to start monitor", e.getMessage(), "Stuffed!");
                        }
                    }

                    @Override
                    public void onCancel(Object arguments) {
                        Log.d(TAG, "----------------------------- cancelling Beacon monitor ..." + new Date().toString());
                        BeaconScanner.stopScan();
                    }
                }
        );

    }

    private void processMonitor() {
        Log.d(TAG, "\nprocessMonitor:  ℹ️  ℹ️  starting Nearby Message Listener");
        Awareness.SnapshotApi.getDetectedActivity(mGoogleApiClient)
                .setResultCallback(new ResultCallback<DetectedActivityResult>() {
                    @Override
                    public void onResult(@NonNull DetectedActivityResult detectedActivityResult) {
                        if (!detectedActivityResult.getStatus().isSuccess()) {
                            Log.e(TAG, "Could not get the current activity.");
                            return;
                        }
                        ActivityRecognitionResult ar = detectedActivityResult.getActivityRecognitionResult();
                        DetectedActivity probableActivity = ar.getMostProbableActivity();
                        Log.i(TAG, probableActivity.toString());
                    }
                });
        mMessageListener = new MessageListener() {
            @Override
            public void onFound(Message message) {
                String msg = new String(message.getContent());
                Log.d(TAG, " \uD83D\uDD35  \uD83D\uDD35 ++++++++ Found message: " + msg);
                monitorEvents.success(GSON.toJson(message));
            }

            @Override
            public void onLost(Message message) {
                Log.d(TAG, "+++++++++++++   ℹ️ Lost sight of message: " + new String(message.getContent()));
                monitorEvents.success(GSON.toJson(message));
            }
        };
    }
    static final Gson GSON = new GsonBuilder().setPrettyPrinting().create();
    private void processBeaconScan() {
        new EventChannel(getFlutterView(), BEACON_SCAN_CHANNEL).setStreamHandler(
                new EventChannel.StreamHandler() {

                    @Override
                    public void onListen(Object arguments, EventChannel.EventSink events) {
                        Log.d(TAG, "\n\n### +++++++++++++++++++++++++++ starting EstimoteBeacon Scan stream ..."
                                + new Date().toString());
                        scanEvents = events;
                        try {
                            BeaconScanner.scanBeacons(getApplicationContext(), events);
                        } catch (Exception e) {
                            Log.e(TAG, "onListen: could not scan beacons", e);
                            scanEvents.error("Unable to start scan", e.getMessage(), "Stuffed!");
                        }
                    }

                    @Override
                    public void onCancel(Object arguments) {
                        Log.d(TAG, "----------------------------- cancelling EstimoteBeacon scan ..." + new Date().toString());
                        BeaconScanner.stopScan();
                    }
                }
        );
    }
    @Override
    public void onStart() {
        super.onStart();
        Log.d(TAG, "onStart:  ℹ️ Subscribing to Nearby messages ..........");
        Nearby.getMessagesClient(this).subscribe(mMessageListener);
    }

    @Override
    public void onStop() {
        Log.d(TAG, "onStop: ⚠️ ⚠️ Unsubscribing from Nearby messages");
        Nearby.getMessagesClient(this).unsubscribe(mMessageListener);
        super.onStop();
    }

    private class EventMessage {
        String message;
        int code;

        public EventMessage(String message, int code) {
            this.message = message;
            this.code = code;
        }
    }
}

