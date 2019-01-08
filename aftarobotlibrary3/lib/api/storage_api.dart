import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:aftarobotlibrary3/api/file_util.dart';
import 'package:aftarobotlibrary3/util/functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageAPI {
  static FirebaseStorage _firebaseStorage = FirebaseStorage.instance;
  static Random rand = new Random(new DateTime.now().millisecondsSinceEpoch);

  // ignore: missing_return
  static uploadLogFile({UploadListener listener}) async {
    rand = new Random(new DateTime.now().millisecondsSinceEpoch);
    var name =
        'AftaRobotLogFile@' + getUTCDate() + '_${rand.nextInt(1000)} +.json';
    try {
      File file = await LocalDB.getLogs();
      print('StorageAPI.uploadFile ------------ path: ${file.path}');
      final StorageReference firebaseStorageRef =
          FirebaseStorage.instance.ref().child("aftaRobotLogs").child(name);

      var task = firebaseStorageRef.putFile(file);
      task.events.listen((event) {
        var totalByteCount = event.snapshot.totalByteCount;
        var bytesTransferred = event.snapshot.bytesTransferred;
        var bt = (bytesTransferred / 1024).toStringAsFixed(2) + ' KB';
        var tot = (totalByteCount / 1024).toStringAsFixed(2) + ' KB';
        print(
            'StorageAPI.uploadFile:  progress ******* $bt KB of $tot KB transferred');
        if (listener != null) listener.onProgress(tot, bt);
      });
      task.onComplete.then((snap) {
        var totalByteCount = snap.totalByteCount;
        var bytesTransferred = snap.bytesTransferred;
        var bt = (bytesTransferred / 1024).toStringAsFixed(2) + ' KB';
        var tot = (totalByteCount / 1024).toStringAsFixed(2) + ' KB';
        file.delete();
        printLog(
            'StorageAPI.uploadFile:  logFile upload complete ******* $bt KB of $tot KB transferred. ${DateTime.now().toIso8601String()}\n\n');
        if (listener != null)
          listener.onComplete(
              firebaseStorageRef.getDownloadURL().toString(), tot, bt);
      }).catchError((e) {
        printLog(e);
        if (listener != null) listener.onError('File upload failed');
      });
    } catch (e) {
      printLog(e);
      if (listener != null) listener.onError('Houston, we have a problem $e');
    }
  }

  // ignore: missing_return
  static Future<int> deleteFolder(String folderName) async {
    printLog('StorageAPI.deleteFolder ######## deleting $folderName');
    var task = _firebaseStorage.ref().child(folderName).delete();
    await task.then((f) {
      printLog(
          'StorageAPI.deleteFolder $folderName deleted from FirebaseStorage');
      return 0;
    }).catchError((e) {
      printLog('StorageAPI.deleteFolder ERROR $e');
      return 1;
    });
  }

  // ignore: missing_return
  static Future<int> deleteFile(String folderName, String name) async {
    printLog('StorageAPI.deleteFile ######## deleting $folderName : $name');
    var task = _firebaseStorage.ref().child(folderName).child(name).delete();
    task.then((f) {
      printLog(
          'StorageAPI.deleteFile $folderName : $name deleted from FirebaseStorage');
      return 0;
    }).catchError((e) {
      printLog('StorageAPI.deleteFile ERROR $e');
      return 1;
    });
  }
}

abstract class UploadListener {
  onProgress(String totalByteCount, String bytesTransferred);
  onComplete(String url, String totalByteCount, String bytesTransferred);
  onError(String message);
}
