package com.example.migrator2.api.google;

/**
 * Created by aubreymalabie on 9/6/17.
 */

public class Namespace {
    private String namespaceName, servingVisibility = "PUBLIC";

    public String getNamespaceName() {
        return namespaceName;
    }

    public void setNamespaceName(String namespaceName) {
        this.namespaceName = namespaceName;
    }

    public String getServingVisibility() {
        return servingVisibility;
    }

    public void setServingVisibility(String servingVisibility) {
        this.servingVisibility = servingVisibility;
    }
}
