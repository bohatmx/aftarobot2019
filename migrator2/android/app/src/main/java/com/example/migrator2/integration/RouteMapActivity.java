package com.example.migrator2.integration;

import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Log;

import com.example.migrator2.R;

public class RouteMapActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Log.d(this.getClass().getCanonicalName(), "########## RouteMapActivity onFuckingCreate !!! ####################");
        setContentView(R.layout.activity_route_map);
    }
}
