import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get/get.dart';
import 'app/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
   await FlutterDownloader.initialize(
    debug: true, // optional: set false in production
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
