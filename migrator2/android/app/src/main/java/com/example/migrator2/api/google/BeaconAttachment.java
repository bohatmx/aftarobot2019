package com.example.migrator2.api.google;

import java.io.Serializable;

/**
 * Created by aubreymalabie on 6/11/16.
 */
public class BeaconAttachment implements Serializable{
    private String attachmentName, namespacedType, data, creationTimeMs;

    public String getAttachmentName() {
        return attachmentName;
    }

    public void setAttachmentName(String attachmentName) {
        this.attachmentName = attachmentName;
    }

    public String getNamespacedType() {
        return namespacedType;
    }

    public void setNamespacedType(String namespacedType) {
        this.namespacedType = namespacedType;
    }

    public String getData() {
        return data;
    }

    public void setData(String data) {
        this.data = data;
    }

    public String getCreationTimeMs() {
        return creationTimeMs;
    }

    public void setCreationTimeMs(String creationTimeMs) {
        this.creationTimeMs = creationTimeMs;
    }
}
