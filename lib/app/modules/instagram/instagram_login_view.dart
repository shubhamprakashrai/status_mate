import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class InstagramStorySaverPage extends StatefulWidget {
  const InstagramStorySaverPage({super.key});

  @override
  State<InstagramStorySaverPage> createState() => _InstagramStorySaverPageState();
}

class _InstagramStorySaverPageState extends State<InstagramStorySaverPage> {
  late final WebViewController _controller;
  String extractedMedia = '';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('StoryChannel', onMessageReceived: (msg) {
        setState(() {
          extractedMedia = msg.message; // This will be the image or video URL
        });
        print('Story Media URL: $extractedMedia');
      })
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (url) {
          if (url.contains("instagram.com/stories/")) {
            _injectStoryScraperScript();
          }
        },
      ))
      ..loadRequest(Uri.parse("https://www.instagram.com/accounts/login/"));
  }

  Future<void> _injectStoryScraperScript() async {
    const js = '''
    setTimeout(() => {
      const video = document.querySelector('video');
      const img = document.querySelector('img');
      const mediaUrl = video?.src || img?.src || 'no_media_found';
      StoryChannel.postMessage(mediaUrl);
    }, 3000);
    ''';
    await _controller.runJavaScript(js);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Instagram Story Saver')),
      body: Column(
        children: [
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
          if (extractedMedia.isNotEmpty && extractedMedia != 'no_media_found')
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Image.network(extractedMedia, height: 200, fit: BoxFit.cover),
                  ElevatedButton(
                    onPressed: () => _downloadMedia(extractedMedia),
                    child: const Text("Download"),
                  )
                ],
              ),
            )
        ],
      ),
    );
  }

  


  void _downloadMedia(String url) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = url.split('/').last.split('?').first;
    final filePath = '${dir.path}/$fileName';

    final response = await Dio().download(url, filePath);
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloaded to $filePath')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Download failed: $e')),
    );
  }
}

}
