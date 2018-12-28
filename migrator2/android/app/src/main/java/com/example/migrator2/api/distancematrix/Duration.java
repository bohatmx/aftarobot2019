package com.example.migrator2.api.distancematrix;

import java.io.Serializable;

/**
 * Created by aubreymalabie on 9/18/16.
 */


public class Duration implements Serializable {
    private int value;

    public int getValue() {
        return this.value;
    }

    public void setValue(int value) {
        this.value = value;
    }

    private String text;

    public String getText() {
        return this.text;
    }

    public void setText(String text) {
        this.text = text;
    }
}
