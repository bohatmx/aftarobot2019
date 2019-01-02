package com.example.migrator2;

import android.app.NotificationChannel;
import android.app.NotificationManager;
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
import android.support.v4.app.NotificationCompat;
import android.util.Base64;
import android.util.Log;
import android.widget.Toast;

import com.estimote.mustard.rx_goodness.rx_requirements_wizard.Requirement;
import com.estimote.mustard.rx_goodness.rx_requirements_wizard.RequirementsWizardFactory;
import com.estimote.proximity_sdk.api.EstimoteCloudCredentials;
import com.estimote.proximity_sdk.api.ProximityObserver;
import com.estimote.proximity_sdk.api.ProximityObserverBuilder;
import com.estimote.proximity_sdk.api.ProximityZone;
import com.estimote.proximity_sdk.api.ProximityZoneBuilder;
import com.estimote.proximity_sdk.api.ProximityZoneContext;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.List;
import java.util.Objects;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;
import kotlin.Unit;
import kotlin.jvm.functions.Function0;
import kotlin.jvm.functions.Function1;

import static java.util.Locale.getDefault;

public class MainActivity extends FlutterActivity {
    static final Gson GSON = new GsonBuilder().setPrettyPrinting().create();

    private static final String BATTERY_CHANNEL = "samples.flutter.io/battery";
    private static final String BEACON_SCAN_CHANNEL = "aftarobot/beaconScan";
    private static final String BEACON_PROXIMITY_CHANNEL = "aftarobot/beaconProximity";

    MethodCall methodCall;
    MethodChannel.Result methodResult;
    EventChannel.EventSink scanEvents, proximityEvents;
    private ProximityObserver proximityObserver;
    NotificationCompat.Builder mBuilder;
    EstimoteCloudCredentials cloudCredentials =
            new EstimoteCloudCredentials("migrator-h4s", "54f62ce67e7773ecedbcea816271c50e");
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Log.d(this.getClass().getCanonicalName(), "###### MainActivity onCreate() .................");
        GeneratedPluginRegistrant.registerWith(this);

        mBuilder = new NotificationCompat.Builder(this, BEACON_PROXIMITY_CHANNEL)
                .setSmallIcon(R.drawable.ic_launcher)
                .setContentTitle("Content Title")
                .setContentText("Content Text")
                .setPriority(NotificationCompat.PRIORITY_DEFAULT);
        mBuilder.build();
        createNotificationChannel();




        new EventChannel(getFlutterView(), BEACON_PROXIMITY_CHANNEL).setStreamHandler(
                new EventChannel.StreamHandler() {

                    @Override
                    public void onListen(Object arguments, EventChannel.EventSink events) {
                        Log.d(TAG, "\n\n### ++++++++++++++++++++++++++++ starting Beacon Proximity stream ..."
                                + new Date().toString());
                        proximityEvents = events;
                        if (proximityEvents != null)
                        proximityEvents.success(GSON.toJson(new BeaconMessage("Starting Beacon Monitoring ...",new Date().toString())));
                        if (proximityObserver == null) {
                            Log.d(TAG,"\n\n\n@@@@@@@@@@@@@@@@@@@@@@@@ --- set up proximityObserver");
                            proximityObserver =
                                    new ProximityObserverBuilder(getApplicationContext(), cloudCredentials)
                                            .onError(new Function1<Throwable, Unit>() {
                                                @Override
                                                public Unit invoke(Throwable throwable) {
                                                    Log.e(TAG, "---------------> proximity observer error: " + throwable);
                                                    return null;
                                                }
                                            })
                                            .withBalancedPowerMode()
                                            .onError(new Function1<Throwable, Unit>() {
                                                @Override
                                                public Unit invoke(Throwable throwable) {
                                                    System.out.println("Observer is FUCKED!!!!");
                                                    Log.d(TAG, "---------------------------------------------- invoke: Observer is FUCKED");
                                                    proximityEvents.success(GSON.toJson(new BeaconMessage("Observer is FUCKED ...",new Date().toString())));
                                                    return null;
                                                }
                                            })
                                            .build();
                            buildProximity();

                        } else {
                            buildProximity();
                        }
                    }

                    @Override
                    public void onCancel(Object arguments) {
                        Log.d(TAG, "----------------------------- cancelling EstimoteBeacon Proximity ...");

                    }
                }
        );
        new EventChannel(getFlutterView(), BEACON_SCAN_CHANNEL).setStreamHandler(
                new EventChannel.StreamHandler() {

                    @Override
                    public void onListen(Object arguments, EventChannel.EventSink events) {
                        Log.d(TAG, "\n\n### +++++++++++++++++++++++++++ starting EstimoteBeacon Scan stream ..."
                                + new Date().toString());
                        scanEvents = events;
                        processBeaconRequest();
                    }

                    @Override
                    public void onCancel(Object arguments) {
                        Log.d(TAG, "----------------------------- cancelling EstimoteBeacon scan ..." + new Date().toString());
                        scanner.stopScan(scanCallback);
                    }
                }
        );

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
    private void createNotificationChannel() {
        // Create the NotificationChannel, but only on API 26+ because
        // the NotificationChannel class is new and not in the support library
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            CharSequence name = "AftaRobot";
            String description = "Channel Description";
            int importance = NotificationManager.IMPORTANCE_DEFAULT;
            NotificationChannel channel = new NotificationChannel(BEACON_PROXIMITY_CHANNEL, name, importance);
            channel.setDescription(description);
            // Register the channel with the system; you can't change the importance
            // or other notification behaviors after this
            NotificationManager notificationManager = getSystemService(NotificationManager.class);
            notificationManager.createNotificationChannel(channel);
        }
    }
    private void buildProximity() {
        Log.d(TAG, "\n################# buildProximity method starting ... #################################");
        proximityEvents.success(GSON.toJson(new BeaconMessage("buildProximity method starting ...",new Date().toString())));
        final ProximityZone zone = new ProximityZoneBuilder()
                .forTag("vehicles")
                .inCustomRange(3.0)
//                .inNearRange()
                .onEnter(new Function1<ProximityZoneContext, Unit>() {
                    @Override
                    public Unit invoke(ProximityZoneContext context) {
                        Log.e(TAG, "\n###################### .............................. " +
                                "ENTERING beacon range ..." + new Date().toString());
                        BeaconFound found = getBeacon(context);
                        found.isEnter = true;
                        Log.d(TAG, "++++++++ ++++++++++++++++++++++++++++++++++++++++++++++ " +
                                "ENTER: Beacon found: " + GSON.toJson(found));
                        proximityEvents.success(GSON.toJson(found));
                        return null;
                    }
                })
                .onExit(new Function1<ProximityZoneContext, Unit>() {
                    @Override
                    public Unit invoke(ProximityZoneContext context) {
                        Log.e(TAG, "\n########################### ------------------------------------ " +
                                "EXITTING beacon range ...");
                        BeaconFound found = getBeacon(context);
                        found.isEnter = true;
                        Log.d(TAG, "############################# EXIT: Beacon found: " + GSON.toJson(found));
                        proximityEvents.success(GSON.toJson(found));
                        return null;
                    }
                })

                .build();
        Log.d(TAG,"@@@@@@@@@@@@@@@ creating RequirementsWizardFactory ......................");
        proximityEvents.success(GSON.toJson(new BeaconMessage("creating RequirementsWizardFactory ..",new Date().toString())));
        RequirementsWizardFactory
                .createEstimoteRequirementsWizard()
                .fulfillRequirements(this,
                        // onRequirementsFulfilled
                        new Function0<Unit>() {
                            @Override public Unit invoke() {
                                Log.d("PAY_OFF", "+++++++++++++++++++++++++++++++++++++++" +
                                        " requirements fulfilled. start observing .....");
                                proximityEvents.success(GSON.toJson(new BeaconMessage("proximity requirements fulfilled. start observing ..",new Date().toString())));
                                Log.d(TAG,"%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% set up ProximityObserver.Handler. use later for stopping");
                                observationHandler =
                                        proximityObserver
                                                .startObserving(zone);
                                Log.d(TAG, "\n\n++++++++++++++++++++++++++++++ observing has started. Fingers crossed XXX");
                                proximityEvents.success(GSON.toJson(new BeaconMessage("observing has started. Fingers crossed XXs",new Date().toString())));

                                return null;
                            }
                        },
                        // onRequirementsMissing
                        new Function1<List<? extends Requirement>, Unit>() {
                            @Override public Unit invoke(List<? extends Requirement> requirements) {
                                Log.e("FUCK_THIS", "----------- requirements missing: " + requirements);
                                return null;
                            }
                        },
                        // onError
                        new Function1<Throwable, Unit>() {
                            @Override public Unit invoke(Throwable throwable) {
                                Log.e("REQ_FUCKUP", "********** requirements error: " + throwable);
                                return null;
                            }
                        });

    }
    ProximityObserver.Handler observationHandler;
    BeaconFound getBeacon(ProximityZoneContext context) {
        Log.d(TAG,"++++++++++++++++++++++++++++++ creating BeaconFound object +++++++++++++++++");
        String vehicleID = context.getAttachments().get("vehicleID");
        String vehicleReg = context.getAttachments().get("vehicleReg");
        String make = context.getAttachments().get("make");
        String model = context.getAttachments().get("model");
        return new BeaconFound(vehicleReg, vehicleID, make, model, false);
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

    private class BeaconFound {
        String vehicleReg, vehicleID, make, model;
        boolean isEnter;

        public BeaconFound(String vehicleReg, String vehicleID, String make, String model, boolean isEnter) {
            this.vehicleReg = vehicleReg;
            this.vehicleID = vehicleID;
            this.make = make;
            this.model = model;
            this.isEnter = isEnter;
        }
    }

    private class EstimoteBeacon {
        String beaconName, advertisedId;

        public String getBeaconName() {
            return beaconName;
        }

        public void setBeaconName(String beaconName) {
            this.beaconName = beaconName;
        }

        public String getAdvertisedId() {
            return advertisedId;
        }

        public void setAdvertisedId(String advertisedId) {
            this.advertisedId = advertisedId;
        }
    }

    private class BeaconMessage {
        String message, timestamp;

        public BeaconMessage(String message, String timestamp) {
            this.message = message;
            this.timestamp = timestamp;
        }
    }
    private class Error {
        String message, reason;

        public Error(String message, String reason) {
            this.message = message;
            this.reason = reason;
        }
    }
    @Override
    protected void onDestroy() {
        Log.d(TAG,"-------------------------- onDestroy: ........... observationHandler.stop();");
        observationHandler.stop();
        super.onDestroy();
    }
}
