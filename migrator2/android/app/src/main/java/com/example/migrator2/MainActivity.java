package com.example.migrator2;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothManager;
import android.bluetooth.le.BluetoothLeScanner;
import android.bluetooth.le.ScanCallback;
import android.bluetooth.le.ScanFilter;
import android.bluetooth.le.ScanRecord;
import android.bluetooth.le.ScanResult;
import android.bluetooth.le.ScanSettings;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.ContextWrapper;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.BatteryManager;
import android.os.Build;
import android.os.Bundle;
import android.os.ParcelUuid;
import android.util.Base64;
import android.util.Log;
import android.widget.Toast;

import com.example.migrator2.api.LocationPair;
import com.example.migrator2.api.MapsAPI;
import com.example.migrator2.api.directions.DirectionsResponse;
import com.example.migrator2.api.distancematrix.DistanceMatrixResponse;
import com.example.migrator2.api.google.AdvertisedId;
import com.example.migrator2.api.google.EstimoteBeacon;
import com.example.migrator2.integration.RouteMapActivity;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Objects;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

import static java.util.Locale.getDefault;

public class MainActivity extends FlutterActivity {
    static final Gson GSON = new GsonBuilder().setPrettyPrinting().create();

    private static final String BATTERY_CHANNEL = "samples.flutter.io/battery";
    private static final String DIRECTIONS_CHANNEL = "aftarobot/directions";
    private static final String DISTANCE_CHANNEL = "aftarobot/distance";
    private static final String BEACON_SCAN_CHANNEL = "aftarobot/beaconScan";

    MethodCall methodCall;
    MethodChannel.Result methodResult;
    EventChannel.EventSink scanEvents;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Log.d(this.getClass().getCanonicalName(), "###### MainActivity onCreate() .................");
        GeneratedPluginRegistrant.registerWith(this);

        new EventChannel(getFlutterView(), BEACON_SCAN_CHANNEL).setStreamHandler(
                new EventChannel.StreamHandler() {
                    private BroadcastReceiver chargingStateChangeReceiver;
                    @Override
                    public void onListen(Object arguments, EventChannel.EventSink events) {
                        Log.d(TAG, "\n\n### +++++++++++++++ starting EstimoteBeacon Scan stream ...");
                        scanEvents = events;
                        processBeaconRequest();
                    }

                    @Override
                    public void onCancel(Object arguments) {
                        Log.d(TAG, "----------------------------- cancelling EstimoteBeacon scan ...");
                        scanner.stopScan(scanCallback);
                    }
                }
        );
        new MethodChannel(getFlutterView(), DISTANCE_CHANNEL).setMethodCallHandler(
                new MethodChannel.MethodCallHandler() {
                    @Override
                    public void onMethodCall(MethodCall call, final MethodChannel.Result result) {
                        methodCall = call;
                        methodResult = result;
                        processDistanceRequest();
                    }
                });
        new MethodChannel(getFlutterView(), DIRECTIONS_CHANNEL).setMethodCallHandler(
                new MethodChannel.MethodCallHandler() {
                    @Override
                    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
                        Log.d(TAG,"++++++++ starting processDirectionsRequest ........" );
                        methodCall = call;
                        methodResult = result;
                        processDirectionsRequest();
                    }
                });
        new MethodChannel(getFlutterView(), BATTERY_CHANNEL).setMethodCallHandler(
                new MethodChannel.MethodCallHandler() {
                    @Override
                    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
                        Log.d("MainActivity", "Inside native Android .............");
                        methodCall = call;
                        methodResult = result;
                        if (call.method.equals("getBatteryLevel")) {
                            int batteryLevel = getBatteryLevel();

                            if (batteryLevel != -1) {
                                result.success(batteryLevel);
                            } else {
                                result.error("UNAVAILABLE", "Battery level not available.", null);
                            }
                        } else {
                            result.notImplemented();
                        }
                    }
                });
    }

    private void processDistanceRequest() {
        Log.d(TAG, "############################ processDistanceRequest -----------------");
        if (methodCall.method.equals("getDistance")) {
            LocationPair locationPair;
            Object args = methodCall.arguments;
            if (args instanceof String) {
                String json = (String) args;
                locationPair = GSON.fromJson(json, LocationPair.class);
            } else {
                methodResult.error("Invalid locationPair data received", "Error", "FuckedUp");
                return;
            }
            if (locationPair != null) {
                MapsAPI.getDistanceMatrix(locationPair.getOrigin(), locationPair.getDestination(), new MapsAPI.DistanceMatrixListener() {
                    @Override
                    public void onResponse(DistanceMatrixResponse response) {
                        String json = GSON.toJson(response);
                        Log.d(TAG, GSON.toJson(response));
                        methodResult.success(json);
                    }

                    @Override
                    public void onError(String message) {
                        Log.e(TAG, message);
                        methodResult.error(message, null, null);
                    }
                });
            }
        } else {
            methodResult.notImplemented();
        }
    }

    private void processDirectionsRequest() {
        Log.d(TAG, "############################ processDirectionsRequest -----------------");
        if (methodCall.method.equals("getDirections")) {
            LocationPair locationPair;
            Object args = methodCall.arguments;
            if (args instanceof String) {
                String json = (String) args;
                Log.d(TAG, "RECECIVED on Android side: " + json);
                locationPair = GSON.fromJson(json, LocationPair.class);
            } else {
                methodResult.error("Invalid locationPair data received", "Error", "FuckedUp");
                return;
            }
            if (locationPair != null) {
                MapsAPI.getDirections(locationPair.getOrigin(), locationPair.getDestination(), new MapsAPI.DirectionsListener() {

                    @Override
                    public void onResponse(DirectionsResponse response) {
                        String json = GSON.toJson(response);
                        Log.d(TAG, GSON.toJson(response));
                        methodResult.success(json);
                    }

                    @Override
                    public void onError(String message) {
                        Log.e(TAG, message);
                        methodResult.error(message, null, null);
                    }
                });
            }
        } else {
            methodResult.notImplemented();
        }
    }

    private int getBatteryLevel() {
        Log.d(this.getClass().getCanonicalName(), "####### getBatteryLevel method running ..........");
        int batteryLevel = -1;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            BatteryManager batteryManager = (BatteryManager) getSystemService(BATTERY_SERVICE);
            batteryLevel = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY);
        } else {
            Intent intent = new ContextWrapper(getApplicationContext()).
                    registerReceiver(null, new IntentFilter(Intent.ACTION_BATTERY_CHANGED));
            batteryLevel = (intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) * 100) /
                    intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1);
        }

        return batteryLevel;
    }

    private static final String TAG = MainActivity.class.getSimpleName();

    private void startRouteMap() {
        Log.w(this.getClass().getCanonicalName(), "..... startRouteMap ....... HOLD YOUR FUCKING BREATH!!");
        Intent m = new Intent(this, RouteMapActivity.class);
        m.putExtra("landmark", "some location data");
        startActivity(m);
    }
    int count;
    private ScanCallback scanCallback;

    private void processBeaconRequest() {
        scanBeacons();
    }
    private void scanBeacons() {

        Log.w(TAG, "\n\n+++ scanBeacons: $$$$$$$$$$$$$$$$$$$$$ -------------------------- Keep the old fingers crossed!");
        count = 0;
        scanCallback = new ScanCallback() {
            @Override
            public void onScanResult(int callbackType, ScanResult result) {
                Log.d(TAG, "++++ we have a ScanResult +++++++++ power level: " +
                        Objects.requireNonNull(result.getScanRecord()).getTxPowerLevel());
                ScanRecord scanRecord = result.getScanRecord();
                if (scanRecord == null) {
                    Log.w(TAG, "Null ScanRecord for device " + result.getDevice().getAddress());
                    return;
                }
                byte[] serviceData = scanRecord.getServiceData(EDDYSTONE_SERVICE_UUID);
                if (serviceData == null) {
                    return;
                }
                if (serviceData[0] != EDDYSTONE_UID_FRAME_TYPE) {
                    return;
                }

                // Extract the arBeacon ID from the service data. Offset 0 is the frame type, 1 is the
                // See https://github.com/google/eddystone/eddystone-uid for more information.
                byte[] id = Arrays.copyOfRange(serviceData, 2, 18);
                String beaconID = Utils.toHexString(id);
                String advertiseId = Base64.encodeToString(id, Base64.DEFAULT).trim();
                Log.i(TAG, "onScanResult: advertiseId: ".concat(advertiseId));

                EstimoteBeacon estimoteBeacon = new EstimoteBeacon();
                estimoteBeacon.setAdvertisedId(advertiseId);
                estimoteBeacon.setBeaconName(beaconID);

                Log.d(TAG, "\n\n++++++++++ sending estimoteBeacon to Flutter, found: " + GSON.toJson(estimoteBeacon));
                scanEvents.success(GSON.toJson(estimoteBeacon));

            }

            @Override
            public void onScanFailed(int errorCode) {
                Log.e(TAG, "onScanFailed errorCode " + errorCode);
                scanEvents.error("EstimoteBeacon scanning failed", "Error Code: " + errorCode, "FuckedUp!");
            }
        };

        createScanner();

    }

    public static final int REQUEST_CODE_ENABLE_BLE = 564;
    private BluetoothLeScanner scanner;
    // An aggressive scan for nearby devices that reports immediately.
    private static final ScanSettings SCAN_SETTINGS =
            new ScanSettings.Builder().
                    setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
                    .setReportDelay(0)
                    .build();

    // The Eddystone-UID frame type byte.
    // See https://github.com/google/eddystone for more information.
    private static final byte EDDYSTONE_UID_FRAME_TYPE = 0x00;

    // The Eddystone Service UUID, 0xFEAA.
    private static final ParcelUuid EDDYSTONE_SERVICE_UUID =
            ParcelUuid.fromString("0000FEAA-0000-1000-8000-00805F9B34FB");

    // A filter that scans only for devices with the Eddystone Service UUID.
    private static final ScanFilter EDDYSTONE_SCAN_FILTER = new ScanFilter.Builder()
            .setServiceUuid(EDDYSTONE_SERVICE_UUID)
            .build();

    private static final List<ScanFilter> SCAN_FILTERS = buildScanFilters();

    private static List<ScanFilter> buildScanFilters() {
        List<ScanFilter> scanFilters = new ArrayList<>();
        scanFilters.add(EDDYSTONE_SCAN_FILTER);
        return scanFilters;
    }

    private void createScanner() {
        Log.d(TAG, "####### running createScanner .............................");
        BluetoothManager btManager =
                (BluetoothManager) getSystemService(Context.BLUETOOTH_SERVICE);
        BluetoothAdapter btAdapter = btManager.getAdapter();
        if (btAdapter == null || !btAdapter.isEnabled()) {
            Intent enableBtIntent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
            startActivityForResult(enableBtIntent, REQUEST_CODE_ENABLE_BLE);
        }
        if (btAdapter == null || !btAdapter.isEnabled()) {
            Log.e(TAG, "Can't enable Bluetooth");
            Toast.makeText(this, "Can't enable Bluetooth", Toast.LENGTH_SHORT).show();
            return;
        }
        scanner = btAdapter.getBluetoothLeScanner();
        Log.w(TAG, "createScanner: scanner acquired");
        scanner.startScan(SCAN_FILTERS, SCAN_SETTINGS, scanCallback);

    }


}
