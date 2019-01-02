package com.example.beaconmanager;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothManager;
import android.bluetooth.le.BluetoothLeScanner;
import android.bluetooth.le.ScanCallback;
import android.bluetooth.le.ScanFilter;
import android.bluetooth.le.ScanRecord;
import android.bluetooth.le.ScanResult;
import android.bluetooth.le.ScanSettings;
import android.content.Context;
import android.content.Intent;
import android.os.ParcelUuid;
import android.util.Base64;
import android.util.Log;
import android.widget.Toast;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Objects;

import io.flutter.plugin.common.EventChannel;

public class BeaconScanner {
    private static final String TAG = "Scanner-Wild Side";
    static int count;
    private static ScanCallback scanCallback;
    private static Context context;
    private static EventChannel.EventSink scanEvents;

    public static void stopScan() {
        if (scanner != null) {
            scanner.stopScan(scanCallback);
        }
        Log.d(TAG, "stopScan: beacon scanning stopped");
    }
    public static void scanBeacons(Context ctx, final EventChannel.EventSink events) throws Exception {
        context = ctx;
        scanEvents = events;

        Log.w(TAG, "\n\n+++ BeaconScanner :: scanBeacons: $$$$$$$$$$$$$$$$$$$$$ " +
                "-------------------------- Keep the fingers crossed!");

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

    private static final Gson GSON = new GsonBuilder().setPrettyPrinting().create();

    private static BluetoothLeScanner scanner;
    private static final ScanSettings SCAN_SETTINGS =
            new ScanSettings.Builder().
                    setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
                    .setReportDelay(0)
                    .build();

    private static final byte EDDYSTONE_UID_FRAME_TYPE = 0x00;
    private static final ParcelUuid EDDYSTONE_SERVICE_UUID =
            ParcelUuid.fromString("0000FEAA-0000-1000-8000-00805F9B34FB");
    private static final ScanFilter EDDYSTONE_SCAN_FILTER = new ScanFilter.Builder()
            .setServiceUuid(EDDYSTONE_SERVICE_UUID)
            .build();

    private static final List<ScanFilter> SCAN_FILTERS = buildScanFilters();

    private static List<ScanFilter> buildScanFilters() {
        List<ScanFilter> scanFilters = new ArrayList<>();
        scanFilters.add(EDDYSTONE_SCAN_FILTER);
        return scanFilters;
    }

    private static void createScanner() throws Exception {
        Log.d(TAG, "####### running createScanner .............................");
        BluetoothManager btManager =
                (BluetoothManager) context.getSystemService(Context.BLUETOOTH_SERVICE);
        BluetoothAdapter btAdapter = btManager.getAdapter();
        if (btAdapter == null || !btAdapter.isEnabled()) {
            throw new Exception("Unable to start Bluetooth");
        }

        scanner = btAdapter.getBluetoothLeScanner();
        Log.w(TAG, "createScanner: scanner acquired");
        scanner.startScan(SCAN_FILTERS, SCAN_SETTINGS, scanCallback);

    }

    private static class EstimoteBeacon {
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
}
