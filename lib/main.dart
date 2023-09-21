import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:advancti_firebase/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants/color_constants.dart';
import 'pages/pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  MyApp({required this.prefs});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appTitle,
      theme: ThemeData(
        primaryColor: ColorConstants.themeColor,
        primarySwatch: MaterialColor(0xff203152, ColorConstants.swatchColor),
      ),
      home: SplashPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
