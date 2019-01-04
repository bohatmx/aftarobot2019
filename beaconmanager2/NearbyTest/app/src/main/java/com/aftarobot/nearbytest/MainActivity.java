package com.aftarobot.nearbytest;

import android.Manifest;
import android.app.PendingIntent;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.location.Location;
import android.os.Bundle;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.support.design.widget.FloatingActionButton;
import android.support.design.widget.Snackbar;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.Toolbar;
import android.util.Log;
import android.view.View;
import android.view.Menu;
import android.view.MenuItem;

import com.estimote.proximity_sdk.api.EstimoteCloudCredentials;
import com.estimote.proximity_sdk.api.ProximityObserver;
import com.estimote.proximity_sdk.api.ProximityObserverBuilder;
import com.estimote.proximity_sdk.api.ProximityZone;
import com.estimote.proximity_sdk.api.ProximityZoneBuilder;
import com.google.android.gms.awareness.Awareness;
import com.google.android.gms.awareness.snapshot.BeaconStateResponse;
import com.google.android.gms.awareness.snapshot.BeaconStateResult;
import com.google.android.gms.awareness.snapshot.DetectedActivityResponse;
import com.google.android.gms.awareness.snapshot.DetectedActivityResult;
import com.google.android.gms.awareness.snapshot.LocationResult;
import com.google.android.gms.awareness.snapshot.PlacesResult;
import com.google.android.gms.awareness.snapshot.WeatherResult;
import com.google.android.gms.awareness.state.BeaconState;
import com.google.android.gms.awareness.state.Weather;
import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.api.GoogleApiClient;
import com.google.android.gms.common.api.ResultCallback;
import com.google.android.gms.common.api.ResultCallbacks;
import com.google.android.gms.common.api.Status;
import com.google.android.gms.location.ActivityRecognitionResult;
import com.google.android.gms.location.DetectedActivity;
import com.google.android.gms.location.places.PlaceLikelihood;
import com.google.android.gms.nearby.Nearby;
import com.google.android.gms.nearby.messages.Message;
import com.google.android.gms.nearby.messages.MessageListener;
import com.google.android.gms.nearby.messages.Strategy;
import com.google.android.gms.nearby.messages.SubscribeOptions;
import com.google.android.gms.tasks.OnCanceledListener;
import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.android.gms.tasks.Task;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.Date;
import java.util.Iterator;
import java.util.List;
import java.util.ListIterator;

import kotlin.Unit;
import kotlin.jvm.functions.Function1;


public class MainActivity extends AppCompatActivity implements GoogleApiClient.OnConnectionFailedListener, GoogleApiClient.ConnectionCallbacks {
    private static final Gson GS = new GsonBuilder().setPrettyPrinting().create();
    public static final int IN_VEHICLE = 0;
    public static final int ON_BICYCLE = 1;
    public static final int ON_FOOT = 2;
    public static final int STILL = 3;
    public static final int UNKNOWN = 4;
    public static final int TILTING = 5;
    public static final int WALKING = 7;
    public static final int RUNNING = 8;

    static final String TAG = "MeMyself";
    GoogleApiClient mGoogleApiClient;
    Toolbar toolbar;

    //AIzaSyC9Qq0qss2GGOO_-VNOWLB5DUjSGqBWe7s
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        toolbar = (Toolbar) findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        mGoogleApiClient = new GoogleApiClient.Builder(MainActivity.this)
                .addApi(Awareness.API)
                .build();
        mGoogleApiClient.connect();
        Log.d(TAG, "onCreate: mGoogleApiClient connecting ...");
        startMessageListener();

        FloatingActionButton fab = findViewById(R.id.fab);
        fab.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                //startMessageListener();
                //backgroundSubscribe();

            }
        });
    }

    MessageListener mMessageListener;

    void startMessageListener() {

        Log.d(TAG, "startMessageListener:  #############################");
        mMessageListener = new MessageListener() {
            @Override
            public void onFound(Message message) {
                Log.d(TAG, "Found message: " + new String(message.getContent()));
                // Do something with the message here.
                Log.i(TAG, "Message found: " + message);
                Log.i(TAG, "Message string: " + new String(message.getContent()));
                Log.i(TAG, "Message namespaced type: " + message.getNamespace() +
                        "/" + message.getType());
            }

            @Override
            public void onLost(Message message) {
                Log.d(TAG, "Lost sight of message: " + new String(message.getContent()));
            }
        };
        Log.i(TAG, "*********** Subscribing.... Strategy.BLE_ONL");
        SubscribeOptions options = new SubscribeOptions.Builder()
                .setStrategy(Strategy.BLE_ONLY)
                .build();
        Nearby.getMessagesClient(this).subscribe(mMessageListener, options);
    }

    @Override
    protected void onStart() {
        super.onStart();
    }

    @Override
    protected void onStop() {
        super.onStop();
    }


    private void detectActivity() {
        Log.d(TAG, "\n\ndetectActivity:  \uD83D\uDD35 ############################################# " + new Date().toString());
        Task<DetectedActivityResponse> task = Awareness.getSnapshotClient(MainActivity.this).getDetectedActivity();
        task.addOnSuccessListener(MainActivity.this, new OnSuccessListener<DetectedActivityResponse>() {
            @Override
            public void onSuccess(DetectedActivityResponse detectedActivityResponse) {
                Log.d(TAG, "detectActivity onSuccess: ".concat(GS.toJson(detectedActivityResponse)));
            }
        }).addOnFailureListener(MainActivity.this, new OnFailureListener() {
            @Override
            public void onFailure(@NonNull Exception e) {
                Log.e(TAG, "detectActivity onFailure: ===============",e );
            }
        }).addOnCanceledListener(MainActivity.this, new OnCanceledListener() {
            @Override
            public void onCanceled() {
                Log.w(TAG, "detectActivity onCanceled: ---------------------------------" );
            }
        });

    }

    private final int MY_PERMISSION_LOCATION = 909;

    private void detectBeacons() {
        Log.d(TAG, "\n\ndetectBeacons:  \uD83D\uDCCD ++++++++++++++++++++++++++++++++++++");
        if (ContextCompat.checkSelfPermission(
                MainActivity.this,
                Manifest.permission.ACCESS_FINE_LOCATION) !=
                PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(
                    MainActivity.this,
                    new String[]{Manifest.permission.ACCESS_FINE_LOCATION},
                    MY_PERMISSION_LOCATION
            );
            return;
        }

        List<BeaconState.TypeFilter> list = new ArrayList<>();
        list.add(BeaconState.TypeFilter.with("namespace", "type"));

        Task<BeaconStateResponse> task = Awareness.getSnapshotClient(this).getBeaconState(list);
        task.addOnSuccessListener(this, new OnSuccessListener<BeaconStateResponse>() {
            @Override
            public void onSuccess(BeaconStateResponse beaconStateResponse) {
                Log.d(TAG, "detectBeacons onSuccess: ".concat(GS.toJson(beaconStateResponse)));
            }
        }).addOnFailureListener(this, new OnFailureListener() {
            @Override
            public void onFailure(@NonNull Exception e) {
                Log.e(TAG, "detectBeacons onFailure: --------  \uD83D\uDCCD ", e );
            }
        }).addOnCanceledListener(MainActivity.this, new OnCanceledListener() {
            @Override
            public void onCanceled() {
                Log.d(TAG, "detectBeacons onCanceled:  \uD83D\uDCCD ------------------------------------------------");
            }
        });

    }

    // Subscribe to messages in the background.
//    private void backgroundSubscribe() {
//        Log.i(TAG, "Subscribing for background updates.");
//        SubscribeOptions options = new SubscribeOptions.Builder()
//                .setStrategy(Strategy.BLE_ONLY)
//                .build();
//        Nearby.getMessagesClient(this).subscribe(getPendingIntent(), options);
//    }
//
//    private PendingIntent getPendingIntent() {
//        return PendingIntent.getBroadcast(this, 0, new Intent(this, BeaconMessageReceiver.class),
//                PendingIntent.FLAG_UPDATE_CURRENT);
//    }
//
//    void getLocation() {
//
//        if (ContextCompat.checkSelfPermission(
//                MainActivity.this,
//                Manifest.permission.ACCESS_FINE_LOCATION) !=
//                PackageManager.PERMISSION_GRANTED) {
//            ActivityCompat.requestPermissions(
//                    MainActivity.this,
//                    new String[]{Manifest.permission.ACCESS_FINE_LOCATION},
//                    MY_PERMISSION_LOCATION
//            );
//            return;
//        }
//        Awareness.SnapshotApi.getLocation(mGoogleApiClient)
//                .setResultCallback(new ResultCallback<LocationResult>() {
//                    @Override
//                    public void onResult(@NonNull LocationResult locationResult) {
//                        if (!locationResult.getStatus().isSuccess()) {
//                            Log.e(TAG, "Could not get location.");
//                            return;
//                        }
//                        Location location = locationResult.getLocation();
//                        Log.i(TAG, "Lat: " + location.getLatitude() + ", Lng: " + location.getLongitude());
//                    }
//                });
//    }
//
//    void getNearbyPlaces() {
//        if (ContextCompat.checkSelfPermission(
//                MainActivity.this,
//                Manifest.permission.ACCESS_FINE_LOCATION) !=
//                PackageManager.PERMISSION_GRANTED) {
//            ActivityCompat.requestPermissions(
//                    MainActivity.this,
//                    new String[]{Manifest.permission.ACCESS_FINE_LOCATION},
//                    MY_PERMISSION_LOCATION
//            );
//            return;
//        }
//        Awareness.SnapshotApi.getPlaces(mGoogleApiClient)
//                .setResultCallback(new ResultCallback<PlacesResult>() {
//                    @Override
//                    public void onResult(@NonNull PlacesResult placesResult) {
//                        if (!placesResult.getStatus().isSuccess()) {
//                            Log.e(TAG, "Could not get places.");
//                            return;
//                        }
//                        List<PlaceLikelihood> placeLikelihoodList = placesResult.getPlaceLikelihoods();
//                        // Show the top 5 possible location results.
//                        for (int i = 0; i < 5; i++) {
//                            PlaceLikelihood p = placeLikelihoodList.get(i);
//                            Log.i(TAG, p.getPlace().getName().toString() + ", likelihood: " + p.getLikelihood());
//                        }
//                    }
//                });
//    }
//
//    void getWeather() {
//        if (ContextCompat.checkSelfPermission(
//                MainActivity.this,
//                Manifest.permission.ACCESS_FINE_LOCATION) !=
//                PackageManager.PERMISSION_GRANTED) {
//            ActivityCompat.requestPermissions(
//                    MainActivity.this,
//                    new String[]{Manifest.permission.ACCESS_FINE_LOCATION},
//                    MY_PERMISSION_LOCATION
//            );
//            return;
//        }
//        Awareness.SnapshotApi.getWeather(mGoogleApiClient)
//                .setResultCallback(new ResultCallback<WeatherResult>() {
//                    @Override
//                    public void onResult(@NonNull WeatherResult weatherResult) {
//                        if (!weatherResult.getStatus().isSuccess()) {
//                            Log.e(TAG, "Could not get weather.");
//                            return;
//                        }
//                        Weather weather = weatherResult.getWeather();
//                        Log.i(TAG, "Weather: " + weather);
//                    }
//                });
//    }

    void showSnack(String message) {
        Snackbar.make(toolbar, message, Snackbar.LENGTH_LONG)
                .setAction("Action", null).show();
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.menu_main, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        int id = item.getItemId();

        //noinspection SimplifiableIfStatement
        if (id == R.id.action_settings) {
            return true;
        }

        return super.onOptionsItemSelected(item);
    }

    @Override
    public void onConnectionFailed(@NonNull ConnectionResult connectionResult) {

    }

    @Override
    public void onConnected(@Nullable Bundle bundle) {
        Log.d(TAG, "onConnected: +++++++++++++++++++++++++++++++++++ ...");
        detectActivity();
        detectBeacons();
    }

    @Override
    public void onConnectionSuspended(int i) {

    }
}
