package com.example.beaconmanager;

import android.os.Bundle;
import android.util.Log;

import java.util.Date;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
  private static final String BEACON_SCAN_CHANNEL = "aftarobot/beaconScan";

  EventChannel.EventSink scanEvents;
  static  final String TAG = "The WildSide";
  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);

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

}
