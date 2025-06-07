import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:status_mate/app/modules/status/view/image_preview.dart';
import 'package:status_mate/app/modules/status/view/video_preview_page.dart';
import '../controllers/status_controller.dart';

class StatusView extends StatelessWidget {
  const StatusView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StatusController());

    return Scaffold(
      appBar: AppBar(
        title: const Text("WhatsApp Statuses"),
        backgroundColor: Colors.green[700],
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.statusList.isEmpty) {
          return const Center(
            child: Text("No statuses found.",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: controller.statusList.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final file = controller.statusList[index];
            final isVideo = file.path.endsWith('.mp4');

            return Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    if (isVideo) {
                      Get.to(() => VideoPreviewPage(file));
                    } else {
                      Get.to(() => ImagePreviewPage(file));
                    }
                  },
                  child: Hero(
                    tag: file.path,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: isVideo
                          ? Container(
                              color: Colors.black26,
                              child: const Center(
                                child: Icon(Icons.videocam,
                                    size: 36, color: Colors.white),
                              ),
                            )
                          : Image.file(
                              file,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                    ),
                  ),
                ),
                // ✅ Download button
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () async {
                      await controller.downloadStatus(file);
                      Get.snackbar(
                        "Downloaded",
                        "Saved to Download/StatusMate",
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.green.shade600,
                        colorText: Colors.white,
                        margin: const EdgeInsets.all(10),
                        icon:
                            const Icon(Icons.check_circle, color: Colors.white),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.download_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
                // ✅ Share button
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: GestureDetector(
                    onTap: () async {
                      await SharePlus.instance.share(
                        ShareParams(
                          files: [XFile(file.path)],
                          text: 'Check out this WhatsApp status!',
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.screen_share,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }),
    );
  }
}
