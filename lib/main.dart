import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get/get.dart';
import 'package:status_mate/core/storage/local_storage_service.dart';
import 'app/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Flutter Downloader
  await FlutterDownloader.initialize(
    debug: true, // optional: set false in production
  );
  
  // Initialize LocalStorageService
  await Get.putAsync<LocalStorageService>(
    () async => await LocalStorageService().init(),
    permanent: true,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: "StatusMate",
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      theme: ThemeData.dark(),
    );
  }
}


