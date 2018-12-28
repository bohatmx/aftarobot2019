package com.example.migrator2.api.google;

import java.io.Serializable;

/**
 * Created by aubreymalabie on 6/11/16.
 */
public class AdvertisedId  implements Serializable
{
    private String type;
    private String id;

    public String getType() { return this.type; }

    public void setType(String type) { this.type = type; }

    public String getId() { return this.id; }

    public void setId(String id) { this.id = id; }
}
