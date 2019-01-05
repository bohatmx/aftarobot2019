package com.aftarobot.migrator2;

import android.Manifest;

import android.content.pm.PackageManager;
import android.os.Bundle;
import android.util.Log;


import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Set;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;


import static java.util.Locale.getDefault;

public class MainActivity extends FlutterActivity {

    static final Gson GSON = new GsonBuilder().setPrettyPrinting().create();
    static final String TAG = "BeaconWildside";
    private static final String BEACON_MONITOR_CHANNEL = "aftarobot/beaconMonitor";
    private static final String BEACON_SCAN_CHANNEL = "aftarobot/beaconScan";

    MessageListener mMessageListener;
    Message mMessage;
    //
    ProximityObserver.Handler proximityHandler;
    private ProximityObserver proximityObserver;
    EventChannel.EventSink monitorEvents, scanEvents;


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Log.d(this.getClass().getCanonicalName(), "\n\n\n###### ***** MainActivity onCreate()   \uD83D\uDD35 .................");
        GeneratedPluginRegistrant.registerWith(this);

        new EventChannel(getFlutterView(), BEACON_SCAN_CHANNEL).setStreamHandler(
                new EventChannel.StreamHandler() {

                    @Override
                    public void onListen(Object arguments, EventChannel.EventSink events) {
                        Log.d(TAG, "\n\n###  \uD83D\uDD35  \uD83D\uDD35  \uD83D\uDD35  +++++++++++++++++++++++++++ starting EstimoteBeacon Scan stream ..."
                                + new Date().toString());
                        scanEvents = events;
                        try {
                            //BeaconScanner.scanBeacons(getApplicationContext(), scanEvents);
                            scanEvents.endOfStream();
                        } catch (Exception e) {
                            Log.e(TAG, "onListen:  . \uD83D\uDD34 could not scan beacons", e);
                            scanEvents.error(" ⚠ ⚠ Unable to start scan", "Error", "Stuffed!");
                        }
                    }

                    @Override
                    public void onCancel(Object arguments) {
                        Log.d(TAG, "-----------------------------  ⚠ ⚠ ⚠ ⚠ cancelling EstimoteBeacon scan ..." + new Date().toString());
                    }
                }
        );
        new EventChannel(getFlutterView(), BEACON_MONITOR_CHANNEL).setStreamHandler(
                new EventChannel.StreamHandler() {

                    @Override
                    public void onListen(Object arguments, EventChannel.EventSink events) {
                        Log.d(TAG, "\n\n###  \uD83D\uDD35  \uD83D\uDD35  \uD83D\uDD35  +++++++++++++++++++++++++++ starting EstimoteBeacon monitor stream ..."
                                + new Date().toString());
                        monitorEvents = events;
                        try {
                            setupEstimoteMonitoring();
                        } catch (Exception e) {
                            Log.e(TAG, "onListen:  . \uD83D\uDD34 could not scan beacons", e);
                            monitorEvents.error(" ⚠ ⚠ Unable to start scan", "Error", "Stuffed!");
                        }
                    }

                    @Override
                    public void onCancel(Object arguments) {
                        Log.d(TAG, "-----------------------------  ⚠ ⚠ ⚠ ⚠ cancelling EstimoteBeacon monitor ..." + new Date().toString());
                    }
                }
        );
        //
        setupMessageListening();
    }

    private void setupMessageListening() {
        Log.d(TAG, "##################### onCreate:   \uD83D\uDD35 creating message listener");
        mMessageListener = new MessageListener() {
            @Override
            public void onFound(Message message) {
                Log.d(TAG, "##### onFound:   \uD83D\uDD35 \uD83D\uDD34 \uD83D\uDD34  **************************** \n".concat(GSON.toJson(message)));
//                progressBar.setVisibility(View.GONE);
//                AttachmentForVehicleDTO att = GSON.fromJson(new String(message.getContent()), AttachmentForVehicleDTO.class);
//                map.put(att.getBeaconName(), att);
//                Set<Map.Entry<String, AttachmentForVehicleDTO>> mset = map.entrySet();
//                attachments.clear();
//                for (Map.Entry<String, AttachmentForVehicleDTO> entry : mset) {
//                    AttachmentForVehicleDTO m = entry.getValue();
//                    attachments.add(m);
//                }

                //Log.d(TAG, "Found vehicle attachment: ".concat(GSON.toJson(att)));
                Log.i(TAG, "  \uD83D\uDD35 Message namespaced type: " + message.getNamespace() +
                        "/" + message.getType());
                Log.i(TAG, "\uD83D\uDD34 Message found: " + message);
                Log.i(TAG, "\uD83D\uDD34 Message string: " + new String(message.getContent()));
                Log.i(TAG, "\uD83D\uDD34 Message namespaced type: " + message.getNamespace() +
                        "/" + message.getType());
            }

            @Override
            public void onLost(Message message) {
                Log.e(TAG, "⚠️⚠️ Lost sight of message: " + new String(message.getContent()));
            }
        };


        mMessage = new Message(" \uD83D\uDD34 ********** Hello World".getBytes());
    }

    private void setupEstimoteMonitoring() {
        String msg = GSON.toJson(new BeaconMessage(" \uD83D\uDD34  Setting up Estimote monitoring", false, false));
        monitorEvents.success(msg);
        EstimoteCloudCredentials cloudCredentials =
                new EstimoteCloudCredentials("aftarobot-s-proximity-for--jup", "3a82fe8c6e5361bb31b4b5c1ae946d38");

        Log.d(TAG, "onCreate: ### Proximity Observer -  \uD83D\uDD35 ");
        this.proximityObserver =
                new ProximityObserverBuilder(getApplicationContext(), cloudCredentials)
                        .onError(new Function1<Throwable, Unit>() {
                            @Override
                            public Unit invoke(Throwable throwable) {
                                Log.e(TAG, "  ⚠ ⚠ proximity observer error: " + throwable);
                                return null;
                            }
                        })
                        .withBalancedPowerMode()
                        .build();
        Log.d(TAG, "onCreate: ### Proximity Zone -  \uD83D\uDD35 set up zone for tag vehicles");
        final ProximityZone zone = new ProximityZoneBuilder()
                .forTag("vehicles")
                .inNearRange()
                .onEnter(new Function1<ProximityZoneContext, Unit>() {
                    @Override
                    public Unit invoke(ProximityZoneContext context) {
                        String vehicleReg = context.getAttachments().get("vehicleReg");
                        Log.d(TAG, " \uD83D\uDD35  \uD83D\uDD35 This beacon belongs to: " + vehicleReg + ". Yebo!");
                        String msg = GSON.toJson(new BeaconMessage(" \uD83D\uDD34 we have found something!!!! ENTERED!", false, false));
                        monitorEvents.success(msg);
                        return null;
                    }
                })
                .onExit(new Function1<ProximityZoneContext, Unit>() {
                    @Override
                    public Unit invoke(ProximityZoneContext context) {
                        Log.d(TAG, " \uD83D\uDD35 Bye bye, come again!");
                        String msg = GSON.toJson(new BeaconMessage(" \uD83D\uDD34 we have lost something!!!! EXIT!", false, false));
                        monitorEvents.success(msg);
                        return null;
                    }
                }).onContextChange(new Function1<Set<? extends ProximityZoneContext>, Unit>() {
                    @Override
                    public Unit invoke(Set<? extends ProximityZoneContext> contexts) {
                        String msg = GSON.toJson(new BeaconMessage(" \uD83D\uDD34 onContextChange: !!!! ENTERED!", false, false));
                        monitorEvents.success(msg);
                        List<String> vehicles = new ArrayList<>();
                        for (ProximityZoneContext context : contexts) {
                            //vehicles.add(context.().get("desk-owner"));
                            Log.d(TAG, "invoke:  \uD83D\uDD34777777777777777777777777777777777777");
                        }
                        Log.d(TAG, " \uD83D\uDD34 In range of vehicles: " + vehicles);
                        return null;
                    }
                })
                .build();
        Log.d(TAG, "onCreate: ### RequirementsWizardFactory starting.  \uD83D\uDD35 checking requirements ...");
        RequirementsWizardFactory
                .createEstimoteRequirementsWizard()
                .fulfillRequirements(MainActivity.this,
                        // onRequirementsFulfilled
                        new Function0<Unit>() {
                            @Override public Unit invoke() {
                                Log.d(TAG, " \uD83D\uDD34 requirements fulfilled. start observing ...\n\n");
                                proximityObserver.startObserving(zone);
                                String msg = GSON.toJson(new BeaconMessage(" \uD83D\uDD34 requirements fulfilled. start observing ...\n\n", false, false));
                                monitorEvents.success(msg);
                                return null;
                            }
                        },
                        // onRequirementsMissing
                        new Function1<List<? extends Requirement>, Unit>() {
                            @Override public Unit invoke(List<? extends Requirement> requirements) {
                                Log.e(TAG, " ⚠  ⚠  ⚠ requirements missing: " + requirements);
                                String msg = GSON.toJson(new BeaconMessage(" \uD83D\uDD34 requirements missing.", false, false));
                                monitorEvents.success(msg);
                                return null;
                            }
                        },
                        // onError
                        new Function1<Throwable, Unit>() {
                            @Override public Unit invoke(Throwable throwable) {
                                Log.e(TAG, " ⚠ ⚠ ⚠ requirements error: " + throwable);
                                String msg = GSON.toJson(new BeaconMessage(" \uD83D\uDD34 requirements error.", false, false));
                                monitorEvents.success(msg);
                                return null;
                            }
                        });
    }

    MessagesClient beaconMessagesClient;
    SubscribeOptions options;

    @Override
    public void onStart() {
        super.onStart();
        Log.d(TAG, "onStart: \uD83D\uDD34 \uD83D\uDD34 ##################################################");
        Log.d(TAG, "onStart: \uD83D\uDD35 ---- publish Hello message and subscribe using messageListener");

        if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION)
                == PackageManager.PERMISSION_GRANTED) {
            beaconMessagesClient = Nearby.getMessagesClient(this, new MessagesOptions.Builder()
                    .setPermissions(NearbyPermissions.BLE)
                    .build());
            Log.d(TAG, "onStart: *** beaconMessagesClient *** set up. \uD83D\uDD34 check messageListener");
            if (mMessageListener == null) {
                Log.e(TAG, "onStart: ⚠️⚠️ mMessageListener is NULL. We have problems, Senor! ⚠️⚠️ ");
            } else {
                Log.d(TAG, "onStart: \uD83D\uDD34 \uD83D\uDD34 subscribing with good messageListener. Fingers crossed!");
                options = new SubscribeOptions.Builder()
                        .setStrategy(Strategy.BLE_ONLY)
                        .build();
                beaconMessagesClient.subscribe(mMessageListener, options);
                Log.d(TAG, "onStart: beaconMessagesClient subscribed, we should be ready for finding beacons! \uD83D\uDD35 \uD83D\uDD35 \uD83D\uDD35 \uD83D\uDD35 \n\n\n");
            }
        }

    }

    @Override
    public void onStop() {
        Log.d(TAG, "onStop: ⚠️⚠️⚠️-----------------------------------------------------");
        //Nearby.getMessagesClient(this).unpublish(mMessage);
        beaconMessagesClient.unsubscribe(mMessageListener);
        Log.d(TAG, "onStop: ⚠️⚠️⚠️--------------- WE ARE GONE - unsubscribed! --------------------------------------");
        super.onStop();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
    }

    private class BeaconMessage{
        String message;
        boolean entered, exited;

        public BeaconMessage(String message, boolean entered, boolean exited) {
            this.message = message;
            this.entered = entered;
            this.exited = exited;
        }
    }
}
