package com.aftarobot.vehicle;

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
import com.google.firebase.firestore.GeoPoint;
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
    public static final String TAG = "VehicleWildSide";
    public static final Gson G = new GsonBuilder().setPrettyPrinting().create();
    private VehicleDTO vehicle;
    MessageListener mMessageListener;
    Message mMessage;
    private static final String TAXI_MESSAGE_CHANNEL = "aftarobot/messages";
    private static final String GEO_QUERY_CHANNEL = "aftarobot/geoQuery";
    private static final String VEHICLE_LOCATION_CHANNEL = "aftarobot/vehicleLocation";
    EventChannel.EventSink messageEvents;
    MethodChannel.Result mResult;
    MethodChannel.Result mVehicleLocationResult;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        GeneratedPluginRegistrant.registerWith(this);

        Log.d(TAG, "\n\nonCreate: \uD83D\uDD35 \uD83D\uDD35 \uD83D\uDD35 set up Taxi Message Channel ...");

//        new EventChannel(getFlutterView(), GEO_QUERY_RESULTS_CHANNEL).setStreamHandler(
//                new EventChannel.StreamHandler() {
//
//                    @Override
//                    public void onListen(Object arguments, EventChannel.EventSink events) {
//                        Log.d(TAG, "\n\n### onListen ++++ \uD83D\uDCCD \uD83D\uDCCD GEO_QUERY_RESULTS_CHANNEL ready to go ... waiting to publish and subscribe. - "
//                                + new Date().toString());
//                        geoQueryEvents = events;
//                        Log.d(TAG, "onCreate: \uD83D\uDD35 \uD83D\uDD35 ### ... wait for request to come in .... ");
//
//
//                        Log.d(TAG, "onCreate: \uD83D\uDD35 \uD83D\uDD35 ### MessagesClient published and subscribed!!! ");
//                    }
//
//                    @Override
//                    public void onCancel(Object arguments) {
//                        Log.d(TAG, "--- onCancel:  \uD83C\uDFBE  \uD83C\uDFBE cancelling EventChannel ..." + new Date().toString());
//                    }
//                }
//        );
        new EventChannel(getFlutterView(), TAXI_MESSAGE_CHANNEL).setStreamHandler(
                new EventChannel.StreamHandler() {

                    @Override
                    public void onListen(Object arguments, EventChannel.EventSink events) {
                        Log.d(TAG, "\n\n### onListen ++++ \uD83D\uDCCD \uD83D\uDCCD TAXI_MESSAGE_CHANNEL ready to go ... waiting to publish and subscribe. - "
                                + new Date().toString());
                        messageEvents = events;
                        Log.d(TAG, "onCreate: \uD83D\uDD35 \uD83D\uDD35 ### trying ... MessagesClient publish and subscribe ");

                        if (vehicle == null) {
                            mMessage = new Message(("AftaRobot Taxi - "
                                    + new Date().getTime()).getBytes());
                        } else {
                            mMessage = new Message(G.toJson(vehicle).getBytes());
                        }
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


        Log.d(TAG, "\n\n onCreate: \uD83D\uDD35 \uD83D\uDD35 \uD83D\uDD35 set up GEO_QUERY_CHANNEL  ...");
        new MethodChannel(getFlutterView(), GEO_QUERY_CHANNEL).setMethodCallHandler(
                new MethodChannel.MethodCallHandler() {
                    @Override
                    public void onMethodCall(MethodCall call, final MethodChannel.Result result) {
                        mResult = result;
                        Object args = call.arguments;

                        Log.d(TAG, "\uD83D\uDCCD\uD83D\uDCCD ****************** onMethodCall: arguments: " + args.toString());
                        GeoRequest geoRequest = G.fromJson(args.toString(), GeoRequest.class);
                        if (call.method.equalsIgnoreCase("findLandmarks")) {
                            findLandmarks(geoRequest);
                        } else {
                            mResult.error("Method not right", "Error", "Like, Fucked!");
                        }
                    }
                });
        ///
        Log.d(TAG, "\n\n onCreate: \uD83D\uDD35 \uD83D\uDD35 \uD83D\uDD35 set up VEHICLE_LOCATION_CHANNEL  ...");
        new MethodChannel(getFlutterView(), VEHICLE_LOCATION_CHANNEL).setMethodCallHandler(
                new MethodChannel.MethodCallHandler() {
                    @Override
                    public void onMethodCall(MethodCall call, final MethodChannel.Result result) {
                        mVehicleLocationResult = result;
                        Object args = call.arguments;

                        Log.d(TAG, "\uD83D\uDCCD\uD83D\uDCCD ****************** onMethodCall: arguments: " + args.toString());
                        VehicleLocationRequest geoRequest = G.fromJson(args.toString(), VehicleLocationRequest.class);
                        if (call.method.equalsIgnoreCase("writeVehicleLocation")) {
                            writeVehicleLocation(geoRequest);
                        } else {
                            mResult.error("Method not right", "Error", "Like, Fucked!");
                        }
                    }
                });
    }

    void writeVehicleLocation(VehicleLocationRequest request) {
        Log.d(TAG, "writeVehicleLocation: ***************************** ");
        GeoPointHelper.writeVehicleLocation(request.vehicleID, request.latitude, request.longitude, new VehiclePointListener() {
            @Override
            public void onGeoPointWritten() {
                String date = new Date().toString();
                Log.d(TAG, "onGeoPointWritten: +++ sending geoVehicleLocations success result back to Flutter at: " + date);
                try {
                    mVehicleLocationResult.success("Vehicle location written to Firestore: geoVehicleLocations: " + date);
                } catch (IllegalStateException e) {
                    Log.e(TAG, "onGeoPointWritten:  ⚠️ ⚠️IllegalStateException - tried to send response back to Flutter ::  ⚠️ ⚠️",e );
                }
            }

            @Override
            public void onError(String message) {
                Log.e(TAG, "onError: " + message );
                mVehicleLocationResult.error(message, "Error", "Fucked!");
            }
        });
    }
    void findLandmarks(GeoRequest request) {
        Log.d(TAG, "findLandmarks: #################################################################");
        GeoPointHelper.findLandmarksWithin(request.latitude, request.longitude, request.radius, new GeoPointListener() {
            @Override
            public void onGeoPointsFound(List<HashMap<String,String>> geoPoints) {
                if (geoPoints.isEmpty()) {
                    Log.d(TAG, "NO GEO POINTS FOUND:   \uD83D\uDD35,  like zero, zilch, nada!");
                } else {
                    Log.d(TAG, "\n\n................. HOOO - FUCKING - RAY!!! *** onGeoPointsFound:  ✅  ✅  ✅ " + geoPoints.size()
                            + " ... sending to Flutter as JSON data\n\n");
                    mResult.success(G.toJson(geoPoints));

                }
            }
        });
    }

    void startMessageListener() {
        Log.d(TAG, "startMessageListener: +++ \uD83D\uDCCD \uD83D\uDCCD  set up Message Listener");
        mMessageListener = new MessageListener() {
            @Override
            public void onFound(Message message) {
                Log.d(TAG, " ✅ Found message: " + new String(message.getContent()));
                Log.d(TAG, " ✅ onFound: namespace: " + message.getNamespace() + " type: " + message.getType());
                messageEvents.success(new String(message.getContent()));
            }

            @Override
            public void onLost(Message message) {
                Log.d(TAG, "\uD83C\uDFBE \uD83C\uDFBE  Lost sight of message: " + new String(message.getContent()));
            }
        };
        IntentFilter filter = new IntentFilter(
                CommuterMessageReceiver.MESSAGE_RECEIVED_INTENT);
        LocalBroadcastManager.getInstance(this)
                .registerReceiver(new CommuterBroadcastReceiver(), filter);
        backgroundSubscribe();
        Log.d(TAG, "startMessageListener: \uD83D\uDD35 MessageListener started. Fingers crossed :)");
    }

    // Subscribe to messages in the background.
    MessagesClient bgMessagesClient, fgMessagesClient, fgPublishClient, bgPublishClient;

    private void backgroundSubscribe() {
        Log.i(TAG, "\uD83D\uDCCD \uD83D\uDCCD Subscribing for background commuter messages....");
        SubscribeOptions options = new SubscribeOptions.Builder()
                .setStrategy(Strategy.BLE_ONLY)
                .build();
        bgMessagesClient = Nearby.getMessagesClient(this);
        bgMessagesClient.subscribe(getPendingIntent(), options);

        bgPublishClient = Nearby.getMessagesClient(this);
        if (vehicle == null) {
            mMessage = new Message(("AftaRobot Taxi - " + new Date().getTime()).getBytes());
        } else {
            mMessage = new Message(G.toJson(vehicle).getBytes());
        }
        bgPublishClient.publish(mMessage);

    }

    private PendingIntent getPendingIntent() {
        return PendingIntent.getBroadcast(this, 0, new Intent(this, CommuterMessageReceiver.class),
                PendingIntent.FLAG_UPDATE_CURRENT);
    }

    public class CommuterBroadcastReceiver extends BroadcastReceiver {

        @Override
        public void onReceive(Context context, Intent intent) {
            String message = intent.getStringExtra("message");
            Log.d(TAG, "CommuterBroadcastReceiver \uD83D\uDCCD onReceive: sending message to Flutter");
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

    private class GeoRequest {
        double latitude,longitude,radius;

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

    private class VehicleLocationRequest {
        double latitude,longitude;
        String vehicleID;

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

        public String getVehicleID() {
            return vehicleID;
        }

        public void setVehicleID(String vehicleID) {
            this.vehicleID = vehicleID;
        }
    }
}

