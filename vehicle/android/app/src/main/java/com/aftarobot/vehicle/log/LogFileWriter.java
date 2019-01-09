package com.aftarobot.vehicle.log;

import android.util.Log;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.Date;

public class LogFileWriter {
    public static final String TAG = LogFileWriter.class.getSimpleName();

    public static void print(String tag, String message) {
        Log.d(tag, message);
        File logFile = new File(LogFileWorker.LOG_FILE_PATH);
        try {
            BufferedWriter out = new BufferedWriter(
                    new FileWriter(logFile, true));
            String x = new Date().toString() + " - " + message;
            out.write(x);
            out.close();
        } catch (IOException e) {
            Log.e(TAG, "ERROR appending log to logFile: ", e);
        }


    }
    public static void clearLog() {
        File logFile = new File(LogFileWorker.LOG_FILE_PATH);
        try {
            BufferedWriter out = new BufferedWriter(
                    new FileWriter(logFile, false));
            String x = "\uD83D\uDD35 \uD83D\uDD35 \uD83D\uDD35 BEGINNING OF THE NEW WORLD ORDER! \uD83D\uDD35 \uD83D\uDD35 \uD83D\uDD35 ️ "+new Date().toString() +"\n\n\n";
            out.write(x);
            out.close();
            Log.d(TAG, "clearLog: ⚠️ ⚠️ " + logFile.getAbsolutePath() + " is " + logFile.length() + " bytes long after clear");
        } catch (IOException e) {
            Log.e(TAG, "ERROR appending log to logFile: ", e);
        }


    }
}
