import 'package:flutter/material.dart';
import 'dart:html' as html; // Import for web reload
import 'Post/post_main.dart'; // A new widget to display all posts with labels
import 'package:bulletin_admin/Account/account_verity.dart';

class AdminHome extends StatelessWidget {
  final String username;

  const AdminHome({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length:
          2, // Updated to reflect the reduced tabs (1 for posts + 1 for account verification)
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
            labelColor: Colors.white,
            unselectedLabelColor: Colors.black,
            indicatorColor: Colors.white,
            tabs: [
              Tab(
                  text:
                      "Posts"), // Merged tab for Pending, Accepted, and Rejected
              Tab(
                  text:
                      "Account Verification"), // New tab for account verification
            ],
          ),
        ),
        body: Stack(
          children: [
            TabBarView(
              children: [
                Post(
                    username:
                        username), // New widget that handles merged post view
                AccountVerification(username: username),
              ],
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                backgroundColor: Colors.grey,
                onPressed: () {
                  html.window.location.reload(); // Handle logout logic
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
