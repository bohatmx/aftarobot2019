package com.aftarobot.vehicle.util;

import java.util.HashMap;
import java.util.List;

public interface AddVehicleLocationListener {
    void onVehicleLocationAdded();
    void onError(String message);
}
