package com.aftarobot.vehicle;

import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.support.v4.content.LocalBroadcastManager;
import android.util.Log;

import com.aftarobot.vehicle.log.LogFileWriter;
import com.aftarobot.vehicle.log.LogFileManager;
import com.aftarobot.vehicle.util.AddVehicleLocationListener;
import com.aftarobot.vehicle.util.GeoPointHelper;
import com.aftarobot.vehicle.util.LandmarkGeoPointListener;
import com.aftarobot.vehicle.util.VehicleDTO;
import com.aftarobot.vehicle.util.VehicleLocation;
import com.aftarobot.vehicle.util.VehicleLocationListener;
import com.aftarobot.vehicle.util.VehicleLocationSearch;
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
    public static final String TAG = "VehicleWildSide";
    public static final Gson G = new GsonBuilder().setPrettyPrinting().create();
    private VehicleDTO vehicle;
    MessageListener mMessageListener;
    Message mMessage;
    private static final String TAXI_MESSAGE_CHANNEL = "aftarobot/messages";
    private static final String GEO_QUERY_CHANNEL = "aftarobot/geoQuery";
    private static final String ADD_VEHICLE_LOCATION_CHANNEL = "aftarobot/vehicleLocation";
    private static final String FIND_VEHICLE_LOCATIONS_CHANNEL = "aftarobot/findVehicleLocations";
    EventChannel.EventSink messageEvents;
    MethodChannel.Result mResult;
    MethodChannel.Result mVehicleLocationResult, mVehicleSearchResult;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        GeneratedPluginRegistrant.registerWith(this);

        LogFileManager.scheduleWork();
        LogFileWriter.print(TAG, "\n\nonCreate: \uD83D\uDD35 \uD83D\uDD35 \uD83D\uDD35 set up Taxi Message Channel ...");

        new EventChannel(getFlutterView(), TAXI_MESSAGE_CHANNEL).setStreamHandler(
                new EventChannel.StreamHandler() {

                    @Override
                    public void onListen(Object arguments, EventChannel.EventSink events) {
                        LogFileWriter.print(TAG, "\n\n### onListen ++++ \uD83D\uDCCD \uD83D\uDCCD TAXI_MESSAGE_CHANNEL ready to go ... waiting to publish and subscribe. - "
                                + new Date().toString());
                        messageEvents = events;
                        LogFileWriter.print(TAG, "onCreate: \uD83D\uDD35 \uD83D\uDD35 ### trying ... MessagesClient publish and subscribe ");

                        Log.d(TAG, "onListen: " + arguments.toString());
                        vehicle = G.fromJson(arguments.toString(), VehicleDTO.class);
                        LogFileWriter.print(TAG, G.toJson(vehicle));
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
        LogFileWriter.print(TAG, "\n\nonCreate: \uD83D\uDD35 \uD83D\uDD35 \uD83D\uDD35 set up ADD_VEHICLE_LOCATION_CHANNEL  ...");
        new MethodChannel(getFlutterView(), ADD_VEHICLE_LOCATION_CHANNEL).setMethodCallHandler(
                new MethodChannel.MethodCallHandler() {
                    @Override
                    public void onMethodCall(MethodCall call, final MethodChannel.Result result) {
                        mVehicleLocationResult = result;
                        Object args = call.arguments;
                        LogFileWriter.print(TAG, "\uD83D\uDCCD\uD83D\uDCCD ****************** onMethodCall: arguments: " + args.toString());
                        AddVehicleLocationRequest geoRequest = G.fromJson(args.toString(), AddVehicleLocationRequest.class);
                        if (call.method.equalsIgnoreCase("writeVehicleLocation")) {
                            writeVehicleLocation(geoRequest);
                        } else {
                            result.error("‼️Method not right", "‼️Error", "‼️Like, Fucked!");
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

    void getVehicle() {


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

    void writeVehicleLocation(AddVehicleLocationRequest request) {
        LogFileWriter.print(TAG, "writeVehicleLocation: ⚠️ ********* request: " + G.toJson(request));
        GeoPointHelper.writeVehicleLocation(request.vehiclePath, request.latitude, request.longitude, new AddVehicleLocationListener() {
            @Override
            public void onVehicleLocationAdded() {
                String date = new Date().toString();
                LogFileWriter.print(TAG, "onVehicleLocationAdded: +++ sending geoVehicleLocations success result back to Flutter at: " + date);
                try {
                    mVehicleLocationResult.success("Vehicle location written to Firestore: geoVehicleLocations: " + date);
                } catch (IllegalStateException e) {
                    Log.e(TAG, "onVehicleLocationAdded:  ⚠️ ⚠️IllegalStateException - tried to send response back to Flutter ::  ⚠️ ⚠️", e);
                }
            }

            @Override
            public void onError(String message) {
                Log.e(TAG, "‼️onError: " + message);
                mVehicleLocationResult.error(message, "‼️Error", "‼️Fucked!");
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
                LogFileWriter.print(TAG, " ✅ onFound: namespace: " + message.getNamespace() + " type: " + message.getType());
                messageEvents.success(new String(message.getContent()));
            }

            @Override
            public void onLost(Message message) {
                LogFileWriter.print(TAG, "\uD83C\uDFBE \uD83C\uDFBE  Lost sight of message: " + new String(message.getContent()));
            }
        };
        IntentFilter filter = new IntentFilter(
                CommuterMessageReceiver.MESSAGE_RECEIVED_INTENT);
        LocalBroadcastManager.getInstance(this)
                .registerReceiver(new CommuterBroadcastReceiver(), filter);
        backgroundSubscribe();
        LogFileWriter.print(TAG, "startMessageListener: \uD83D\uDD35 MessageListener started. Fingers crossed :)");
    }

    // Subscribe to messages in the background.
    MessagesClient bgMessagesClient, fgMessagesClient, fgPublishClient, bgPublishClient;

    private void backgroundSubscribe() {
        LogFileWriter.print(TAG, "\uD83D\uDCCD \uD83D\uDCCD Subscribing for background commuter messages....");
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
            LogFileWriter.print(TAG, "\uD83D\uDD34 CommuterBroadcastReceiver \uD83D\uDCCD onReceive: sending message to Flutter");
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
        try {
            if (fgPublishClient != null && mMessage != null) {
                fgPublishClient.unpublish(mMessage);
                bgPublishClient.unpublish(mMessage);
            }
            if (bgMessagesClient != null && mMessage != null) {
                bgMessagesClient.unsubscribe(mMessageListener);
                fgMessagesClient.unsubscribe(mMessageListener);
            }
        } catch (Exception e) {
            Log.e(TAG, "onStop: unable to unpublish");
        }
        super.onStop();
        LogFileWriter.print(TAG, "onStop: ###  \uD83C\uDFBE \uD83C\uDFBE MessagesClient un-publish and unsubscribe ");
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

    private class AddVehicleLocationRequest {
        double latitude, longitude;
        String vehiclePath;

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

        public String getVehiclePath() {
            return vehiclePath;
        }

        public void setVehiclePath(String vehiclePath) {
            this.vehiclePath = vehiclePath;
        }
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
}

