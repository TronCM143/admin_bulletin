import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:bulletin_admin/admin_home.dart'; // Ensure the path is correct

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyAwE8bxODYauafS2-tkQ5U5DOhKpNJca6M",
      appId: "1:1021715121254:web:825a1f866a66160c44d9a7",
      messagingSenderId: "1021715121254",
      projectId: "bulletin-8e636",
    ),
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Bulletin Board'),
        ),
        body: HomeScreen(), // Call the AllPostsPage here
      ),
    );
  }
}
