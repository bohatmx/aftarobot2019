package com.aftarobot.vehicle.util;

import java.util.List;

public interface VehicleLocationListener {
    void onVehiclesFound(List<VehicleLocation> vehicleLocations);
    void onError(String message);
}
