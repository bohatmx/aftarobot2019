import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:aftarobotlibrary/data/associationdto.dart';
import 'package:path_provider/path_provider.dart';

class FileUtil {
  static File jsonFile;
  static Directory dir;
  static bool fileExists;

  static Future<int> saveInvoiceBids(AssociationDTO bids) async {
    Map map = bids.toJson();
    dir = await getApplicationDocumentsDirectory();
    jsonFile = new File(dir.path + "/invoiceBids.json");
    fileExists = await jsonFile.exists();

    if (fileExists) {
      print('FileUtil_saveInvoiceBids  ## file exists ...writing bids file');
      jsonFile.writeAsString(json.encode(map));
      return 0;
    } else {
      print(
          'FileUti_saveInvoiceBids ## file does not exist ...creating and writing bids file');
      var file = await jsonFile.create();
      await file.writeAsString(json.encode(map));
      return 0;
    }
  }
}
