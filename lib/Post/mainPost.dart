import 'package:flutter/material.dart';
import 'post_manager.dart';

class Post extends StatelessWidget {
  final String username;

  const Post({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent, // Set background to transparent
      child: PostManager(username: username),
    );
  }
}
