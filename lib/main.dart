import 'package:bulletin_admin/loginpage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'dart:html'; // Import dart:html for document manipulation

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

  // Set the document title
  document.title = "AppDate Admin Dashboard"; // Correct usage

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: LoginPage(), // Call the LoginPage here
      ),
    );
  }
}
