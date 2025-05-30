import 'package:flutter/material.dart';
import 'chat_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local LLM Chat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ChatPage(),
    );
  }
}