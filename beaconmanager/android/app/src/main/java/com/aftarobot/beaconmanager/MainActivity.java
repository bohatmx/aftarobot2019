package com.aftarobot.beaconmanager;

import android.os.Bundle;
import android.util.Log;

import com.google.android.gms.nearby.Nearby;
import com.google.android.gms.nearby.messages.Message;
import com.google.android.gms.nearby.messages.MessageListener;

import java.util.Date;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
    private static final String BEACON_SCAN_CHANNEL = "aftarobot/beaconScan";
    private static final String BEACON_MONITOR_CHANNEL = "aftarobot/beaconMonitor";

    EventChannel.EventSink scanEvents, monitorEvents;
    static final String TAG = "The WildSide";
    MessageListener mMessageListener;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        GeneratedPluginRegistrant.registerWith(this);

        processBeaconScan();
        processMonitor();

    }

    private void processMonitor() {
        Log.d(TAG, "processMonitor:  ℹ️  ℹ️  starting Nearby Message Listener");
        mMessageListener = new MessageListener() {
            @Override
            public void onFound(Message message) {
                String msg = new String(message.getContent());
                Log.d(TAG, " \uD83D\uDD35  \uD83D\uDD35 ++++++++ Found message: " + msg);
            }

            @Override
            public void onLost(Message message) {
                Log.d(TAG, "+++++++++++++ Lost sight of message: " + new String(message.getContent()));
            }
        };
    }

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
}

