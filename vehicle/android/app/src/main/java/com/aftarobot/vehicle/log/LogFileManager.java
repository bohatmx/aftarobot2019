package com.aftarobot.vehicle.log;

import java.util.Date;
import java.util.concurrent.TimeUnit;

import androidx.work.Operation;
import androidx.work.PeriodicWorkRequest;
import androidx.work.WorkManager;

public class LogFileManager {
private static final String TAG = LogFileManager.class.getSimpleName();


    public static void scheduleWork() {
        LogFileWriter.print(TAG, "\n\nscheduleWork:  ⚠️  ⚠️ setting up work schedule for log file upload\n\n");
        PeriodicWorkRequest.Builder fileUploadBuilder =
                new PeriodicWorkRequest.Builder(LogFileWorker.class, 4,
                        TimeUnit.HOURS);
        fileUploadBuilder.addTag("UploadTag");
        PeriodicWorkRequest uploadLogWork = fileUploadBuilder.build();
        WorkManager.getInstance().enqueue(uploadLogWork);

         LogFileWriter.print(TAG, "scheduleWork:   ⚠️  ⚠️ work schedule enqued for log file upload: " + new Date().toString());
    }
}
