package com.example.migrator2.api.distancematrix;

import java.util.ArrayList;

/**
 * Created by aubreymalabie on 9/18/16.
 */


public class DistanceMatrixResponse {
    private String status;

    public String getStatus() {
        return this.status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    private ArrayList<String> origin_addresses;

    public ArrayList<String> getOriginAddresses() {
        return this.origin_addresses;
    }

    public void setOriginAddresses(ArrayList<String> origin_addresses) {
        this.origin_addresses = origin_addresses;
    }

    private ArrayList<String> destination_addresses;

    public ArrayList<String> getDestinationAddresses() {
        return this.destination_addresses;
    }

    public void setDestinationAddresses(ArrayList<String> destination_addresses) {
        this.destination_addresses = destination_addresses;
    }

    private ArrayList<Row> rows;

    public ArrayList<Row> getRows() {
        return this.rows;
    }

    public void setRows(ArrayList<Row> rows) {
        this.rows = rows;
    }
}
