import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MaterialApp(
    title: "Kxprss",
    debugShowCheckedModeBanner: false,
    localizationsDelegates: [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: [
      Locale('ar', 'EG'),
    ],
    theme: ThemeData(primaryColor: Colors.blue, primarySwatch: Colors.amber),
    home: MyWeb(),
  ));
}

class MyWeb extends StatefulWidget {
  @override
  MyWebState createState() => MyWebState();
}

class MyWebState extends State<MyWeb> with TickerProviderStateMixin {
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();
  late WebViewController _webViewController;
  AnimationController? animation;
  Animation<double>? _fadeInFadeOut;
  @override
  void initState() {
    SystemChrome.setEnabledSystemUIOverlays([]);
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
    super.initState();
    animation = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );
    _fadeInFadeOut = Tween<double>(begin: 0.0, end: 1.0).animate(animation!);
    animation?.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        animation?.reverse();
      } else if (status == AnimationStatus.dismissed) {
        animation?.forward();
      }
    });
    animation?.forward();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    animation!.stop();
    animation!.dispose();
    super.dispose();
  }

  int position = 1;
  bool isLoaded = true;
  final _key = UniqueKey();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: position, children: <Widget>[
        WebView(
          key: _key,
          initialUrl: 'http://demo.sherktk.com/kxprss/',
          onWebViewCreated: (WebViewController webViewController) {
            _controller.complete(webViewController);
            _webViewController = webViewController;
          },
          onPageStarted: (String url) {
            setState(() {
              isLoaded = true;
              position = 1;
            });
          },
          javascriptMode: JavascriptMode.unrestricted,
          onPageFinished: (finish) async {
            try {
              var javascript = '''
              window.alert = function (e){
                Alert.postMessage(e);
              }
            ''';
              await _webViewController.evaluateJavascript(javascript);
            } catch (e) {
              print(e);
            }
            setState(() {
              isLoaded = false;
              position = 0;
            });
          },
          onProgress: (int progress) {
            print("WebView is loading (progress : $progress%)");
          },
          javascriptChannels: <JavascriptChannel>{
            _toasterJavascriptChannel(context),
          },
        ),
        Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FadeTransition(
                opacity: _fadeInFadeOut!,
                child: Image.asset("images/logo.png")),
            //CircularProgressIndicator(),
          ],
        )),
      ]),
    );
  }

  JavascriptChannel _toasterJavascriptChannel(BuildContext context) {
    return JavascriptChannel(
        name: 'Alert',
        onMessageReceived: (JavascriptMessage message) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                backgroundColor: Colors.amber,
                content: Text(
                  message.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
                )),
          );
        });
  }
}
