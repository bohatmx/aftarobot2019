package com.aftarobot.commuter.maps;

public class Battery {
    double level;
    boolean isCharging;

    public double getLevel() {
        return level;
    }

    public void setLevel(double level) {
        this.level = level;
    }

    public boolean isCharging() {
        return isCharging;
    }

    public void setCharging(boolean charging) {
        isCharging = charging;
    }
}
