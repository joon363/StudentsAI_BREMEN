import 'package:flutter/material.dart';
import 'package:students_ai_app/pages/main_page.dart';
import 'package:students_ai_app/themes.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Upstage Paper Assistant',
      theme: AppTheme.lightTheme(context),
      home: ChatbotPage(),
    );
  }
}

