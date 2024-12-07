import 'package:flutter/material.dart';
import 'dart:html' as html; // Import for web reload
import 'Post/accepted_post.dart';
import 'Post/pending_post.dart';
import 'Post/rejected_post.dart';

class AdminHome extends StatelessWidget {
  final String username;

  const AdminHome({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Make sure this matches the number of children in TabBarView
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green.shade600,
          elevation: 0,
          title: const Text(
            'Admin Dashboard',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          bottom: const TabBar(
            labelColor: Colors.white, // Text color for selected tab
            unselectedLabelColor:
                Colors.black, // Text color for unselected tabs
            indicatorColor: Colors.white, // Underline color
            tabs: [
              Tab(text: "Pending"),
              Tab(text: "Accepted"),
              Tab(text: "Rejected"),
            ],
          ),
        ),
        body: Stack(
          children: [
            TabBarView(
              children: [
                PendingPosts(
                    username: username), // Pass the username dynamically
                AcceptedPosts(
                    username: username), // Pass the username dynamically
                RejectedPost(username: username),
              ],
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                backgroundColor: Colors.grey,
                onPressed: () {
                  // Handle logout logic here
                  html.window.location.reload();
                },
                child: const Icon(Icons.logout),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
