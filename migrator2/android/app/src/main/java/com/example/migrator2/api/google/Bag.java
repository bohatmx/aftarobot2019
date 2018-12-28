package com.example.migrator2.api.google;

import java.io.Serializable;
import java.util.ArrayList;

/**
 * Created by aubreymalabie on 6/11/16.
 */
public class Bag  implements Serializable {

        private ArrayList<EstimoteBeacon> estimoteBeacons;

        public ArrayList<EstimoteBeacon> getEstimoteBeacons() { return this.estimoteBeacons; }

        public void setEstimoteBeacons(ArrayList<EstimoteBeacon> estimoteBeacons) { this.estimoteBeacons = estimoteBeacons; }

        private String nextPageToken;

        public String getNextPageToken() { return this.nextPageToken; }

        public void setNextPageToken(String nextPageToken) { this.nextPageToken = nextPageToken; }

        private String totalCount;

        public String getTotalCount() { return this.totalCount; }

        public void setTotalCount(String totalCount) { this.totalCount = totalCount; }

}
