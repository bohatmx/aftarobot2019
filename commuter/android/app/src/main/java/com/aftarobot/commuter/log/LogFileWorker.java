package com.aftarobot.commuter.log;

import android.annotation.SuppressLint;
import android.content.Context;
import android.net.Uri;
import android.support.annotation.NonNull;
import android.util.Log;

import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.common.util.concurrent.ListenableFuture;
import com.google.firebase.storage.FirebaseStorage;
import com.google.firebase.storage.OnProgressListener;
import com.google.firebase.storage.UploadTask;

import java.io.File;
import java.util.Date;

import androidx.work.ListenableWorker;
import androidx.work.ListenableWorker.Result;
import androidx.work.WorkerParameters;

/*
import android.content.Context;
import androidx.work.ListenableWorker;
import androidx.work.ListenableWorker.Result;
import androidx.work.WorkerParameters;
import com.google.common.util.concurrent.ListenableFuture;
 */

public class LogFileWorker extends ListenableWorker {

    private static final String TAG = LogFileWorker.class.getSimpleName();
    public static final String LOG_FILE_PATH = "/data/user/0/com.aftarobot.commuter/app_flutter/LogData0.log";
    /**
     * @param appContext   The application {@link Context}
     * @param workerParams Parameters to setup the internal state of this worker
     */
    public LogFileWorker(@NonNull final Context appContext, @NonNull WorkerParameters workerParams) {
        super(appContext, workerParams);
    }

    @SuppressWarnings("ConstantConditions")
    @NonNull
    @Override
    public ListenableFuture<Result> startWork() {
        Log.d(TAG, "\n\n\nstartWork:  \uD83D\uDCCD  \uD83D\uDCCD ########################## upload log file");
        try {
            FirebaseStorage fss = FirebaseStorage.getInstance();
            @SuppressLint("SdCardPath") final File logFile = new File(LOG_FILE_PATH);
            Log.d(TAG, "startWork:  \uD83C\uDFBE FILE file on the WildSide is: " + logFile.getAbsolutePath() + " "
            + new Date().toString());
            if (logFile.exists()) {
                LogFileWriter.print(TAG, "startWork:  \uD83D\uDCCD  \uD83D\uDCCD logFile exists. will start uploading ...");
                fss.getReference("aftarobotLogs/logfile" + new Date().toString() + ".log").putFile(Uri.fromFile(logFile))
                        .addOnSuccessListener(new OnSuccessListener<UploadTask.TaskSnapshot>() {
                            @Override
                            public void onSuccess(UploadTask.TaskSnapshot taskSnapshot) {
                                Log.d(TAG, "onSuccess: ✅ ######### logfile uploaded to Firebase storage ✅ - "
                                        + new Date().toString() + " " + (taskSnapshot.getTotalByteCount()/1024) + " KB uploaded");
                                Log.d(TAG, "onSuccess: ⚠️ delete logfile after upload ...");
                                LogFileWriter.clearLog();
                            }
                        }).addOnFailureListener(new OnFailureListener() {
                    @Override
                    public void onFailure(@NonNull Exception e) {
                        Log.e(TAG, "onFailure:  ⚠️  ⚠️  ⚠️ logfile upload failed", e);
                    }
                }).addOnProgressListener(new OnProgressListener<UploadTask.TaskSnapshot>() {
                    @Override
                    public void onProgress(UploadTask.TaskSnapshot taskSnapshot) {
                        Log.d(TAG, "onProgress: transferred: " + taskSnapshot.getBytesTransferred() + " bytes of "
                                + taskSnapshot.getTotalByteCount() + " bytes");
                    }
                });

            } else {
                Log.d(TAG, "startWork:  ⚠️ logFile does not exist. no file to upload");
            }
        } catch (Exception e) {
            Log.e(TAG, "‼️‼️startWork: weird return problem: " + e.getMessage());
        }

        try {
            androidx.work.ListenableWorker.Result success = androidx.work.ListenableWorker.Result.success();
            return (ListenableFuture<Result>) success;
        } catch (ClassCastException e) {
            Log.d(TAG, "‼️‼️startWork: ClassCastException with the fucking ListenableFuture<Result> " + e.getMessage() );
            return null;
        }

    }

}
