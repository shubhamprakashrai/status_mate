import 'package:get/get.dart';
import 'package:status_mate/app/modules/instagram/controllers/instagram_controllers.dart';
import 'package:status_mate/app/modules/instagram/instagram_user_input_url.dart';
import 'package:status_mate/app/modules/splash/controolers/splash_controller.dart';
import 'package:status_mate/app/modules/status/view/status_view.dart';
import '../modules/splash/views/splash_view.dart';
import '../modules/status/controllers/status_controller.dart';
import 'app_routes.dart';

class AppPages {
  static const initial = Routes.splash;

  static final routes = [
    GetPage(
      name: Routes.splash,
      page: () => const SplashView(),
      binding: BindingsBuilder(() {
        Get.put(SplashController());
      }),
    ),
    GetPage(
      name: Routes.status,
      page: () => const StatusView(),
      binding: BindingsBuilder(() {
        Get.put(StatusController());
      }),
    ),

   GetPage(
      name: Routes.instagram,
      page: () => const InstagramUrlInputPage(),
      binding: BindingsBuilder(() {
        Get.put(InstagramControllers());
      }),
    ),
  ];
}

// https://www.figma.com/design/lxlpPbJlTiMV86NbzhETGn/Status-Saver-for-WhatsApp-App-Design--Community-?node-id=8004-492&t=E10mCw3TlhkLHVka-0