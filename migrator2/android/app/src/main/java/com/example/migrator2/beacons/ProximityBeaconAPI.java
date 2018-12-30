// Copyright 2015 Google Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package com.example.migrator2.beacons;

import android.accounts.Account;
import android.content.Context;
import android.os.AsyncTask;
import android.util.Log;

import com.example.migrator2.api.google.BeaconAttachment;
import com.google.android.gms.auth.GoogleAuthUtil;
import com.google.android.gms.auth.UserRecoverableAuthException;
import com.google.firebase.auth.FirebaseAuth;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.squareup.okhttp.Callback;
import com.squareup.okhttp.MediaType;
import com.squareup.okhttp.OkHttpClient;
import com.squareup.okhttp.Request;
import com.squareup.okhttp.RequestBody;

import org.json.JSONObject;

import java.io.IOException;

public class ProximityBeaconAPI implements ProximityBeacon {
    private static final String TAG = ProximityBeaconAPI.class.getSimpleName();
    private static final String ENDPOINT = "https://proximitybeacon.googleapis.com/v1beta1/";
    private static final String SCOPE = "oauth2:https://www.googleapis.com/auth/userlocation.beacon.registry";
    public static final MediaType MEDIA_TYPE_JSON = MediaType.parse("application/json; charset=utf-8");

    private static final int GET = 0;
    private static final int PUT = 1;
    private static final int POST = 2;
    private static final int DELETE = 3;

    private static String email;
    private static final OkHttpClient httpClient = new OkHttpClient();
    private static Context context;


    public ProximityBeaconAPI(Context ctx) {
        this.context = ctx;
        this.email = FirebaseAuth.getInstance().getCurrentUser().getEmail();
    }


    @Override
    public void getForObserved(Callback callback, JSONObject requestBody, String apiKey) {
        // The authorization step here isn't strictly necessary. The API key is enough.
        new BeaconsTask("beaconinfo:getforobserved?key=" + apiKey, POST, requestBody.toString(), callback).execute();
    }

    @Override
    public void activateBeacon(Callback callback, String beaconName) {
        new BeaconsTask(beaconName + ":activate", POST, "", callback).execute();
    }

    @Override
    public void deleteBeacon(Callback callback, String beaconName) {
        new BeaconsTask(beaconName, DELETE, "", callback).execute();
    }

    @Override
    public void deactivateBeacon(Callback callback, String beaconName) {
        new BeaconsTask(beaconName + ":deactivate", POST, "", callback).execute();
    }

    @Override
    public void decommissionBeacon(Callback callback, String beaconName) {
        new BeaconsTask(beaconName + ":decommission", POST, "", callback).execute();
    }

    @Override
    public void getBeacon(Callback callback, String beaconName) {
        new BeaconsTask(beaconName, callback).execute();
    }

    @Override
    public void listBeacons(Callback callback, String query) {
        new BeaconsTask("beacons" + "?pageSize=1000&q=" + query, callback).execute();
    }

    @Override
    public void registerBeacon(Callback callback, String beaconJSON) {
        new BeaconsTask("beacons:register", POST, beaconJSON, callback).execute();
    }

    @Override
    public void updateBeacon(Callback callback, String beaconName, String beaconJSON) {
        new BeaconsTask(beaconName, PUT, beaconJSON, callback).execute();
    }

    @Override
    public void batchDeleteAttachments(Callback callback, String beaconName) {
        new BeaconsTask(beaconName + "/attachments:batchDelete", POST, "", callback).execute();
    }

    @Override
    public void createAttachment(Callback callback, String beaconName, String attachmentJSON) {
        new AttachmentTask(beaconName.concat("/attachments"), POST, beaconName, attachmentJSON, callback).execute();
    }

    @Override
    public void deleteAttachment(Callback callback, String attachmentName) {
        Log.d(TAG, "deleteAttachment: ".concat(attachmentName));
        new AttachmentTask(attachmentName, DELETE, callback).execute();
    }

    @Override
    public void listAttachments(Callback callback, String beaconName) {
        new BeaconsTask(beaconName + "/attachments?namespacedType=*/*", callback).execute();
    }

    @Override
    public void listDiagnostics(Callback callback, String beaconName) {
        new BeaconsTask(beaconName + "/diagnostics", callback).execute();
    }

    @Override
    public void listNamespaces(Callback callback) {
        new BeaconsTask("namespaces", callback).execute();
    }

    @Override
    public void updateNamespace(Callback callback, String namespaceJSON) {
        new BeaconsTask("namespaces:update", PUT, namespaceJSON, callback).execute();
    }

    public static final String AUTHORIZATION = "Authorization";
    public static final String BEARER = "Bearer ";
    public static final Gson GSON = new GsonBuilder().setPrettyPrinting().create();

    private static class BeaconsTask extends AsyncTask<Void, Void, Integer> {

        private String urlPart;
        private int method;
        private String json;
        private Callback callback;
        private Request request;
        private Account account;

        public BeaconsTask(String urlPart, Callback callback) {
            this(urlPart, GET, "", callback);
        }

        public BeaconsTask(String urlPart, int method, String json, Callback callback) {
            this.urlPart = urlPart;
            this.method = method;
            this.json = json;
            this.callback = callback;
        }

        @Override
        protected Integer doInBackground(Void... params) {

            Log.d(TAG, "doInBackground..............getting token ....");
            account = new Account(email, "com.google");
            String tok = SharedUtil.getAuthToken(context);
            if (tok == null) {
                return IO_EXCEPTION;
            }
            Log.e(TAG, "doInBackground: auth token: ".concat(tok) );
            if (tok == null) {
                return IO_EXCEPTION;
            }
            Request.Builder requestBuilder = new Request.Builder()
                    .header(AUTHORIZATION, BEARER + tok)
                    .url(ENDPOINT + urlPart);
            switch (method) {
                case PUT:
                    requestBuilder.put(RequestBody.create(MEDIA_TYPE_JSON, json));
                    break;
                case POST:
                    requestBuilder.post(RequestBody.create(MEDIA_TYPE_JSON, json));
                    break;
                case DELETE:
                    requestBuilder.delete();
                    break;
                default:
                    break;
            }
            Log.w(TAG, "Authentication: requestBuilder.build() and newCall ....");
            request = requestBuilder.build();
            httpClient.newCall(request).enqueue(new HttpCallback(callback));


            return 0;
        }


        @Override
        protected void onPostExecute(Integer result) {
            Log.d(TAG, "BeaconsTask onPostExecute: #################################");

            if (result > 0) {
                callback.onFailure(request, new IOException("AuthTask failed"));
            } else
                Log.w(TAG, "BeaconsTask onPostExecute: ***** looks cool. are we sure? yup!");
        }
    }

    private static UserRecoverableAuthException userRecoverableAuthException;

    private static class AttachmentTask extends AsyncTask<Void, Void, Integer> {

        private BeaconAttachment attachment;
        private String beaconName;
        private String urlPart;
        private int method;
        private String json;
        private Callback callback;
        private Request request;


        public AttachmentTask(String urlPart, int method, String beaconName, String json, Callback callback) {
            this.urlPart = urlPart;
            this.method = method;
            this.json = json;
            this.beaconName = beaconName;
            this.callback = callback;
            this.attachment = new BeaconAttachment();
            attachment.setData(encodeJSON(json));
            String namespace = SharedUtil.getNamespace(context);
            attachment.setNamespacedType(namespace.concat("/json"));

        }

        public AttachmentTask(String urlPart, int method, Callback callback) {
            this.urlPart = urlPart;
            this.method = method;
            this.callback = callback;

        }

        @Override
        protected Integer doInBackground(Void... voids) {
            try {
                Account account = new Account(email, "com.google");
                String tok = GoogleAuthUtil.getToken(context, account, SCOPE);
                Request.Builder requestBuilder = new Request.Builder()
                        .header(AUTHORIZATION, BEARER + tok)
                        .url(ENDPOINT + urlPart);
                switch (method) {
                    case PUT:
                        requestBuilder.put(RequestBody.create(MEDIA_TYPE_JSON, GSON.toJson(attachment)));
                        break;
                    case POST:
                        requestBuilder.post(RequestBody.create(MEDIA_TYPE_JSON, GSON.toJson(attachment)));
                        break;
                    case DELETE:
                        requestBuilder.delete();
                        break;
                    default:
                        break;
                }
                request = requestBuilder.build();
                httpClient.newCall(request).enqueue(new HttpCallback(callback));

            } catch (Exception e) {
                Log.e(TAG, "AttachmentTask failed", e);
            }
            return 0;
        }

        @Override
        protected void onPostExecute(Integer result) {
            Log.d(TAG, "AttachmentTask onPostExecute: #################################");
            if (result > 0) {
                callback.onFailure(request, new IOException("AttachmentTask failed"));
            } else
                Log.w(TAG, "AttachmentTask onPostExecute: looks cool, is it?");
        }
    }


    private static String encodeJSON(String json) {


        String shit = android.util.Base64.encodeToString(json.getBytes(), android.util.Base64.NO_WRAP);
        Log.i(TAG, "encodeJSON: " + shit);
        return shit;
    }

    public static final int USER_RECOVERABLE_AUTH_EXCEPTION = 1,
            AUTH_EXCEPTION = 2, IO_EXCEPTION = 3;
}
