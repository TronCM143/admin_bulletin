import 'package:flutter/material.dart';
import 'post_manager.dart';

class Post extends StatelessWidget {
  final String username;

  const Post({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return PostManager(username: username);
  }
}
