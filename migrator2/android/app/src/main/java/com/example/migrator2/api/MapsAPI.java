package com.example.migrator2.api;


import android.util.Log;

import com.example.migrator2.api.directions.DirectionsResponse;
import com.example.migrator2.api.directions.Route;
import com.example.migrator2.api.distancematrix.DistanceMatrixResponse;
import com.example.migrator2.api.roads.RoadsResponse;
//import com.google.android.gms.maps.model.LatLng;
//import com.google.android.gms.maps.model.PolylineOptions;
import com.example.migrator2.integration.RouteMapActivity;
import com.google.android.gms.maps.model.LatLng;
import com.google.android.gms.maps.model.PolylineOptions;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.squareup.okhttp.Call;
import com.squareup.okhttp.Callback;
import com.squareup.okhttp.OkHttpClient;
import com.squareup.okhttp.Request;
import com.squareup.okhttp.Response;

import java.io.IOException;
import java.util.List;
import java.util.concurrent.TimeUnit;

/**
 * Created by aubreymalabie on 7/24/16.
 */
public class MapsAPI {
    public static final String TAG = MapsAPI.class.getSimpleName();
    public interface DirectionsListener {
        void onResponse(DirectionsResponse response);
        void onError(String message);
    }
    public interface DistanceMatrixListener {
        void onResponse(DistanceMatrixResponse response);
        void onError(String message);
    }
    public interface RoadsListener {
        void onResponse(RoadsResponse response);
        void onError(String message);
    }
    static OkHttpClient client = new OkHttpClient();
    static PolylineOptions lineOptions;
    static DirectionsListener listener;
    int color;
    public static final String DISTANCE_MATRIX_API_KEY = "AIzaSyDWg376OStHCLb8LN4ePBNXfhf4cgbnp7Y",
        DISTANCE_MATRIX_URL = "https://maps.googleapis.com/maps/api/distancematrix/json?units=metric&",
        ROADS_API_KEY = "AIzaSyDpwCJ3BXYbpKBMVXp25DRQoeXujihxsn0",
                SNAP_TO_ROADS_URL = "https://roads.googleapis.com/v1/snapToRoads?",
        DIRECTIONS_API_KEY = "AIzaSyBsGlYoIr1T2yZzV6svIbNyt6xOc3hBBoc";

    public static final Gson gson = new Gson();

    public static void getSnappedPoints(List<LatLng> points, final RoadsListener listener) {
        Log.d(RouteMapActivity.class.getCanonicalName(), "######## getSnappedPoints ##################");
        StringBuilder sb = new StringBuilder();
        sb.append(SNAP_TO_ROADS_URL);
        sb.append("path=");
        int index = 0;
        for (LatLng m: points) {
            sb.append(m.latitude).append(",").append(m.longitude);
            if (index == points.size() - 1) {
                break;
            }
            sb.append("|");
            index++;
        }
        sb.append("&key=").append(ROADS_API_KEY);
        sb.append("&interpolate=true");
        String url = sb.toString();

        configureTimeouts(client);
        Log.w(TAG, "### sending request to Google Roads server"
                + "\n" + url);

        Request okHttpRequest = new Request.Builder()
                .url(url)
                .build();
        Call call = client.newCall(okHttpRequest);
        call.enqueue(new Callback() {
            @Override
            public void onFailure(Request request, IOException e) {
                Log.e(TAG, "onFailure: request: " + request.toString(), e );
                listener.onError("Unable to get snapped points");
            }

            @Override
            public void onResponse(Response response) throws IOException {
                String path = response.body().string();
                RoadsResponse dmr = gson.fromJson(path,RoadsResponse.class);
                Log.i(TAG, "Snapped points: " + path);
                listener.onResponse(dmr);

            }
        });
    }
    static final Gson GSON = new GsonBuilder().setPrettyPrinting().create();

    public static void testDistanceMatrix(final DistanceMatrixListener listener) {
        Log.d(RouteMapActivity.class.getCanonicalName(), "######## testDistanceMatrix ##################");
        LatLng origin = new LatLng(-25.760531399999998, 27.8526112);
        LatLng dest = new LatLng(-26.10069, 28.065964399999984);
        getDistanceMatrix(origin, dest, listener);
    }
    public static void testDirections(final DirectionsListener listener) {
        Log.d(RouteMapActivity.class.getCanonicalName(), "######## testDistanceMatrix ##################");
        LatLng origin = new LatLng(-25.760531399999998, 27.8526112);
        LatLng dest = new LatLng(-26.10069, 28.065964399999984);
        getDirections(origin, dest, listener);
    }
    public static void getDistanceMatrix(LatLng originLatLng, LatLng destLatlng, final DistanceMatrixListener listener ) {
        Log.d(RouteMapActivity.class.getCanonicalName(), "######## getDistanceMatrix ##################");
        StringBuilder sb = new StringBuilder();
        sb.append(DISTANCE_MATRIX_URL);
        sb.append("origins=").append(originLatLng.latitude).append(",").append(originLatLng.longitude);
        sb.append("&destinations=").append(destLatlng.latitude).append(",").append(destLatlng.longitude);
        sb.append("&key=").append(DISTANCE_MATRIX_API_KEY);
        String url = sb.toString();
        configureTimeouts(client);
        Log.w(TAG, "### sending request to Google Distance Matrix server"
                + "\n" + url);

        Request okHttpRequest = new Request.Builder()
                .url(url)
                .build();
        Call call = client.newCall(okHttpRequest);
        call.enqueue(new Callback() {
            @Override
            public void onFailure(Request request, IOException e) {
                Log.e(TAG, "onFailure: request: " + request.toString(), e );
                listener.onError("Unable to get directions");
            }

            @Override
            public void onResponse(Response response) throws IOException {
                String path = response.body().string();
                DistanceMatrixResponse dmr = gson.fromJson(path,DistanceMatrixResponse.class);
                Log.i(TAG, "getDistanceMatrix onResponse: distanceMatrix: " + path);
                listener.onResponse(dmr);

            }
        });
    }

    public static void getDirections(LatLng originLatLng, LatLng destLatlng, final DirectionsListener directionsListener) {
        Log.d(RouteMapActivity.class.getCanonicalName(), "######## getDirections ##################");
        listener = directionsListener;
        String str_origin = "origin=" + originLatLng.latitude + "," + originLatLng.longitude;
        String str_dest = "destination=" + destLatlng.latitude + "," + destLatlng.longitude;
        StringBuilder sb = new StringBuilder();
        sb.append("https://maps.googleapis.com/maps/api/directions/json?");
        sb.append(str_origin).append("&").append(str_dest);
        sb.append("&alternatives=true");
        sb.append("&key=").append(DIRECTIONS_API_KEY);

        String url = sb.toString();
        requestGoogleDirections(url,listener);


    }

    private static void requestGoogleDirections(final String url, final DirectionsListener directionsListener) {
        Log.d(RouteMapActivity.class.getCanonicalName(), "######## requestGoogleDirections ##################");
        listener = directionsListener;

        configureTimeouts(client);
        Log.w(TAG, "### sending request to Google DirectionsDTO server"
                + "\n" + url);

        Request okHttpRequest = new Request.Builder()
                .url(url)
                .build();
        Call call = client.newCall(okHttpRequest);
        call.enqueue(new Callback() {
            @Override
            public void onFailure(Request request, IOException e) {
                Log.e(TAG, "onFailure: request: " + request.toString(), e );
                directionsListener.onError("Unable to get directions");
            }

            @Override
            public void onResponse(Response response) throws IOException {
                String path = response.body().string();
                DirectionsResponse dr = gson.fromJson(path,DirectionsResponse.class);
                for (Route k: dr.getRoutes()) {
                    k.getOverviewPolyline().decodePoly();
                }
                Log.i(TAG, "requestGoogleDirections directions retrieved: ");
                directionsListener.onResponse(dr);
            }
        });

    }

    private static void configureTimeouts(OkHttpClient client) {
        client.setConnectTimeout(40, TimeUnit.SECONDS);
        client.setReadTimeout(60, TimeUnit.SECONDS);
        client.setWriteTimeout(40, TimeUnit.SECONDS);

    }

    /**
     * A class to parse the Google Places in JSON format
     */

}
