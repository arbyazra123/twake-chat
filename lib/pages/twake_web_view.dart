import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TwakeWebView extends StatefulWidget {
  final String initUrl;

  const TwakeWebView(
    this.initUrl, {
    Key? key,
  }) : super(key: key);

  @override
  State<TwakeWebView> createState() => _TwakeWebViewState();
}

class _TwakeWebViewState extends State<TwakeWebView> {
  var con = WebViewController();
  @override
  void initState() {
    super.initState();
    con.loadRequest(Uri.parse(widget.initUrl));
    con.setJavaScriptMode(JavaScriptMode.unrestricted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_ios,
            color: Color(0xff3840f7),
          ),
        ),
      ),
      body: SafeArea(
        child: WebViewWidget(
          controller: con,
          // initialMediaPlaybackPolicy: AutoMediaPlaybackPolicy.always_allow,
          // javascriptMode: JavascriptMode.unrestricted,
          // initialUrl: initUrl,
        ),
      ),
    );
  }
}
