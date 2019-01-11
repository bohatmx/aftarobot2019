package com.aftarobot.commuter;

import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.support.v4.content.LocalBroadcastManager;
import android.util.Log;

import com.aftarobot.commuter.log.LogFileWriter;
import com.aftarobot.commuter.util.GeoPointHelper;
import com.aftarobot.commuter.util.LandmarkGeoPointListener;
import com.aftarobot.commuter.util.VehicleLocation;
import com.aftarobot.commuter.util.VehicleLocationListener;
import com.aftarobot.commuter.util.VehicleLocationSearch;
import com.google.android.gms.nearby.Nearby;
import com.google.android.gms.nearby.messages.Message;
import com.google.android.gms.nearby.messages.MessageListener;
import com.google.android.gms.nearby.messages.MessagesClient;
import com.google.android.gms.nearby.messages.Strategy;
import com.google.android.gms.nearby.messages.SubscribeOptions;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import java.util.Date;
import java.util.HashMap;
import java.util.List;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
    public static final String TAG = "CommuterWildSide";
    public static final Gson G = new GsonBuilder().setPrettyPrinting().create();
    MessageListener mMessageListener;
    Message mMessage;
    private static final String TAXI_MESSAGE_CHANNEL = "aftarobot/messages";
    private static final String GEO_QUERY_CHANNEL = "aftarobot/geoQuery";
    private static final String FIND_VEHICLE_LOCATIONS_CHANNEL = "aftarobot/findVehicleLocations";
    EventChannel.EventSink messageEvents;
    MethodChannel.Result mResult, mVehicleSearchResult;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        GeneratedPluginRegistrant.registerWith(this);

        LogFileWriter.print(TAG, "\n\nonCreate: \uD83D\uDD35 \uD83D\uDD35 \uD83D\uDD35 set up Taxi Message Channel");

        new EventChannel(getFlutterView(), TAXI_MESSAGE_CHANNEL).setStreamHandler(
                new EventChannel.StreamHandler() {

                    @Override
                    public void onListen(Object arguments, EventChannel.EventSink events) {
                        LogFileWriter.print(TAG, "\n\n### onListen ++++ \uD83D\uDCCD \uD83D\uDCCD EventChannel ready to go ... waiting to publish and subscribe. - "
                                + new Date().toString());
                        messageEvents = events;
                        LogFileWriter.print(TAG, "onCreate: \uD83D\uDD35 \uD83D\uDD35 ### trying ... MessagesClient publish and subscribe ");

                        String s = "AftaRobot Commuter :: FG " + new Date().getTime();
                        mMessage = new Message(s.getBytes());

                        startMessageListener();
                        fgMessagesClient = Nearby.getMessagesClient(MainActivity.this);
                        fgPublishClient = Nearby.getMessagesClient(MainActivity.this);

                        fgPublishClient.publish(mMessage);
                        fgMessagesClient.subscribe(mMessageListener);
                        LogFileWriter.print(TAG, "onCreate: \uD83D\uDD35 \uD83D\uDD35 ### MessagesClient published and subscribed!!! ");
                    }

                    @Override
                    public void onCancel(Object arguments) {
                        LogFileWriter.print(TAG, "--- onCancel:  \uD83C\uDFBE  \uD83C\uDFBE cancelling EventChannel ..." + new Date().toString());
                    }
                }
        );
        LogFileWriter.print(TAG, "\n\nonCreate: \uD83D\uDD35 \uD83D\uDD35 \uD83D\uDD35 set up GEO_QUERY_CHANNEL  ...");
        new MethodChannel(getFlutterView(), GEO_QUERY_CHANNEL).setMethodCallHandler(
                new MethodChannel.MethodCallHandler() {
                    @Override
                    public void onMethodCall(MethodCall call, final MethodChannel.Result result) {
                        mResult = result;
                        Object args = call.arguments;
                        LogFileWriter.print(TAG, "\uD83D\uDCCD\uD83D\uDCCD ****************** onMethodCall: arguments: " + args.toString());
                        GeoRequest geoRequest = G.fromJson(args.toString(), GeoRequest.class);
                        if (call.method.equalsIgnoreCase("findLandmarks")) {
                            findLandmarks(geoRequest);
                        } else {
                            mResult.error("‼️Method not right", "‼️Error", "‼️Like, Fucked!");
                        }
                    }
                });
        ///

        LogFileWriter.print(TAG, "\n\nonCreate: \uD83D\uDD35 \uD83D\uDD35 \uD83D\uDD35 set up FIND_VEHICLE_LOCATIONS_CHANNEL  ...");
        new MethodChannel(getFlutterView(), FIND_VEHICLE_LOCATIONS_CHANNEL).setMethodCallHandler(
                new MethodChannel.MethodCallHandler() {
                    @Override
                    public void onMethodCall(MethodCall call, final MethodChannel.Result result) {
                        mVehicleSearchResult = result;
                        Object args = call.arguments;
                        LogFileWriter.print(TAG, "\uD83D\uDCCD\uD83D\uDCCD ****************** onMethodCall: arguments: " + args.toString());

                        SearchVehiclesRequest geoRequest = G.fromJson(args.toString(), SearchVehiclesRequest.class);
                        if (call.method.equalsIgnoreCase("findVehicleLocations")) {
                            findVehicleLocations(geoRequest);
                        } else {
                            mVehicleSearchResult.error("‼️Method not right", "‼️Error", "‼️Like, Fucked!");
                        }
                    }
                });
    }

    void findVehicleLocations(SearchVehiclesRequest request) {
        VehicleLocationSearch.findVehicleLocations(request.minutes,
                request.latitude, request.longitude, request.radius, new VehicleLocationListener() {

                    @Override
                    public void onVehiclesFound(List<VehicleLocation> vehicleLocations) {
                        LogFileWriter.print(TAG, "onVehiclesFound: \uD83D\uDD35  \uD83D\uDD35  +++ send found vehicles to Flutter: " + vehicleLocations.size());
                        LogFileWriter.print(TAG, "onVehiclesFound, details, details. what is sent to flutter: ".concat(G.toJson(vehicleLocations)).concat("\n\n"));

                        try {
                            mVehicleSearchResult.success(G.toJson(vehicleLocations));
                        } catch (IllegalStateException e) {
                            LogFileWriter.print(TAG, "onVehiclesFound: ⚠️  ⚠️  ⚠️  ⚠️  run into the familiar problem: " + e.getMessage());
                        }
                    }

                    @Override
                    public void onError(String message) {
                        Log.e(TAG, "onError: ".concat(message));
                        mVehicleSearchResult.error("‼️Failed to find vehicles", message, "‼️Cooked!");
                    }
                });
    }
    void findLandmarks(GeoRequest request) {
        LogFileWriter.print(TAG, "findLandmarks: #################################################################");
        GeoPointHelper.findLandmarksWithin(request.latitude, request.longitude, request.radius, new LandmarkGeoPointListener() {
            @Override
            public void onLandmarkPointsFound(List<HashMap<String, String>> geoPoints) {
                if (geoPoints.isEmpty()) {
                    LogFileWriter.print(TAG, "NO GEO POINTS FOUND:   \uD83D\uDD35,  like zero, zilch, nada!");
                } else {
                    LogFileWriter.print(TAG, "\n\n................. HOOO - FUCKING - RAY!!! *** onLandmarkPointsFound:  ✅  ✅  ✅ " + geoPoints.size()
                            + " ... sending to Flutter as JSON data\n\n");
                    try {
                        mResult.success(G.toJson(geoPoints));
                    } catch (IllegalStateException e) {
                        LogFileWriter.print(TAG, "‼️‼️onLandmarkPointsFound: ⚠️  ⚠️  ⚠️  ⚠️  run into the familiar problem: " + e.getMessage());
                    }

                }
            }
        });
    }

    void startMessageListener() {
        LogFileWriter.print(TAG, "startMessageListener: +++ \uD83D\uDCCD \uD83D\uDCCD  set up Message Listener");
        mMessageListener = new MessageListener() {
            @Override
            public void onFound(Message message) {
                LogFileWriter.print(TAG, " ✅ Found message: " + new String(message.getContent()));
                messageEvents.success(new String(message.getContent()));
            }

            @Override
            public void onLost(Message message) {
                LogFileWriter.print(TAG, "\uD83C\uDFBE \uD83C\uDFBE  Lost sight of message: " + new String(message.getContent()));
            }
        };
        LogFileWriter.print(TAG, "startMessageListener: \uD83D\uDCCD listen for broadcast from TaxiMessageReceiver");
        IntentFilter filter = new IntentFilter(
                TaxiMessageReceiver.MESSAGE_RECEIVED_INTENT);
        LocalBroadcastManager.getInstance(this)
                .registerReceiver(new TaxiBroadcastReceiver(), filter);
        backgroundSubscribe();
        LogFileWriter.print(TAG, "startMessageListener: \uD83D\uDD35 MessageListener started. Fingers crossed :)");
    }

    // Subscribe to messages in the background.
    MessagesClient bgMessagesClient, fgMessagesClient, fgPublishClient, bgPublishClient;

    private void backgroundSubscribe() {
        LogFileWriter.print(TAG, "\uD83D\uDCCD \uD83D\uDCCD Subscribing for background TAXI messages....");
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
            LogFileWriter.print(TAG, "TaxiBroadcastReceiver \uD83D\uDCCD onReceive: sending message to Flutter");
            messageEvents.success(message);
        }
    }
    @Override
    public void onStart() {
        super.onStart();
        LogFileWriter.print(TAG, "onStart: \uD83D\uDD35  \uD83D\uDD35 ### do nuthin ... ");

    }

    @Override
    public void onStop() {
        if (fgPublishClient != null) {
            fgPublishClient.unpublish(mMessage);
        }
        if (bgPublishClient != null) {
            bgPublishClient.unpublish(mMessage);
        }
        if (bgMessagesClient != null && mMessageListener != null) {
            bgMessagesClient.unsubscribe(mMessageListener);
        }
        if (fgMessagesClient != null && mMessageListener != null) {
            fgMessagesClient.unsubscribe(mMessageListener);
        }
        super.onStop();
        LogFileWriter.print(TAG, "onStop: ###  \uD83C\uDFBE \uD83C\uDFBE MessagesClient un-publish and unsubscribe ");
    }
    private class SearchVehiclesRequest {
        double latitude, longitude, radius;
        int minutes;

        public double getLatitude() {
            return latitude;
        }

        public void setLatitude(double latitude) {
            this.latitude = latitude;
        }

        public double getLongitude() {
            return longitude;
        }

        public void setLongitude(double longitude) {
            this.longitude = longitude;
        }

        public double getRadius() {
            return radius;
        }

        public void setRadius(double radius) {
            this.radius = radius;
        }

        public int getMinutes() {
            return minutes;
        }

        public void setMinutes(int minutes) {
            this.minutes = minutes;
        }
    }
    private class GeoRequest {
        double latitude, longitude, radius;

        public double getLatitude() {
            return latitude;
        }

        public void setLatitude(double latitude) {
            this.latitude = latitude;
        }

        public double getLongitude() {
            return longitude;
        }

        public void setLongitude(double longitude) {
            this.longitude = longitude;
        }

        public double getRadius() {
            return radius;
        }

        public void setRadius(double radius) {
            this.radius = radius;
        }
    }

}

