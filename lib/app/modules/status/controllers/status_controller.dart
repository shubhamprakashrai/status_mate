import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;


class StatusController extends GetxController {
  var statusList = <File>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchStatuses();
  }

  Future<void> fetchStatuses() async {
    if (Platform.isAndroid) {
      final manageStatus = await Permission.manageExternalStorage.status;
      final readStatus = await Permission.storage.status;

      if (!manageStatus.isGranted || !readStatus.isGranted) {
        final result = await [
          Permission.manageExternalStorage,
          Permission.storage,
        ].request();

        if (!result[Permission.manageExternalStorage]!.isGranted) {
          Get.snackbar('Permission Needed', 'Grant storage permission from settings');
          await openAppSettings();
          return;
        }
      }
    }

    final dirPath = '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses';
    final dir = Directory(dirPath);

    print("Checking path: $dirPath");

    if (await dir.exists()) {
      final files = dir.listSync().whereType<File>().toList();
      final filtered = files.where((f) =>
          f.path.endsWith('.jpg') || f.path.endsWith('.mp4')).toList();
      statusList.assignAll(filtered);
      print("Statuses found: ${filtered.length}");
    } else {
      print("Directory doesn't exist");
    }

    if (statusList.isEmpty) {
      print("No statuses found.");
    }
  }



  


Future<void> downloadStatus(File file) async {
  final savedDirPath = '/storage/emulated/0/Download/StatusMate';
  final savedDir = Directory(savedDirPath);

  if (!await savedDir.exists()) {
    await savedDir.create(recursive: true);
  }

  final newFilePath = path.join(savedDirPath, path.basename(file.path));
  final newFile = File(newFilePath);

  try {
    await file.copy(newFilePath);

    Get.snackbar(
      "Saved Successfully ✅",
      "File saved to:\n$newFilePath",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade600,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      borderRadius: 10,
      duration: const Duration(seconds: 4),
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  } catch (e) {
    Get.snackbar(
      "Save Failed ❌",
      e.toString(),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade600,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      borderRadius: 10,
      duration: const Duration(seconds: 4),
      icon: const Icon(Icons.error, color: Colors.white),
    );
  }
}







}



